#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "root required";
    exit
fi

usage() {
    echo "usage: -i INTERFACE -n NAMESPACE -a IP -r NAMESERVER -s PROG -c -q"
    echo "  -i INTERFACE            interface pattern like enp+"
    echo "  -n NAMESPACE            the namespace name"
    echo "  -a IP                   ip in the namespace"
    echo "  -r NAMESERVER           nameserver for the namespace"
    echo "  -p PROG                 prog/script to run inside the netns, cleanup will be performed afterwards"
    echo "  -c                      flag, cleansup the namespace created with above options"
    echo "  -q                      quiet"
}

INTERFACE=""
NS_NAME=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
IP="10.200.200"
NAMESERVER="8.8.8.8"
PROG=""
CLEANUP=0
QUIET=0

while getopts "hi:n:a:r:p:cq" opt; do
    case $opt in
        i)
            INTERFACE=$OPTARG;;
        n)
            NS_NAME=$OPTARG;;
        a)
            IP=$OPTARG;;
        r)
            NAMESERVER=$OPTARG;;
        p) 
            PROG=$OPTARG;;
        c) 
            CLEANUP=1;;
        q)
            QUIET=1;;
        h)
            usage
            exit 2;;
        \?)
            usage
            exit 2;;
    esac
done

if [ -z "$INTERFACE" ]; then
    echo "interface pattern required, e.g. et+"
    usage
    exit 2;
fi

setup_ns() {
    ns_name="$1"
    ns_name0="${ns_name}0"
    ns_name1="${ns_name}1"
    ip="$2"

    ip netns del $ns_name 2> /dev/null

    ip netns add $ns_name
    ip netns exec $ns_name ip addr add 127.0.0.1/8 dev lo 
    ip netns exec $ns_name ip link set lo up
    
    ip link add $ns_name0 type veth peer name $ns_name1
    ip link set $ns_name0 up
    ip link set $ns_name1 netns $ns_name up
    ip addr add $ip.1/24 dev $ns_name0
    ip netns exec $ns_name ip addr add $ip.2/24 dev $ns_name1
    ip netns exec $ns_name ip route add default via $ip.1 dev $ns_name1
}

cleanup_ns() {
    ns_name="$1"
    ip="$2"

    ip netns del $ns_name
    ip link delete $ns_name0
}

setup_traffic() {
    ns_name=$1
    ip=$2
    interface=$3

    iptables -A INPUT \! -i $ns_name0 -s $ip.0/24 -j DROP
    iptables -A POSTROUTING -t nat -s $ip.0/24 -o $interface -j MASQUERADE 
    sysctl -q net.ipv4.ip_forward=1
}

cleanup_traffic() {
    ns_name0="${1}0"
    ip=$2
    interface=$3

    iptables -D INPUT \! -i $ns_name0 -s $ip.0/24 -j DROP
    iptables -D POSTROUTING -t nat -s $ip.0/24 -o $interface -j MASQUERADE 
}

setup_nameserver() {
    ns_name=$1
    nameserver=$2

    mkdir -p "/etc/netns/$ns_name"
    echo "nameserver ${nameserver}" > "/etc/netns/$ns_name/resolv.conf"
}

cleanup_nameserver() {
    ns_name=$1

    rm "/etc/netns/$ns_name/resolv.conf"
}
    
if [ "$QUIET" -eq 0 ]; then 
    echo "cleanup? $CLEANUP"
    echo "namespace name: $NS_NAME"
    echo "ip: $IP"
    echo "interface: $INTERFACE"
    echo "nameserver: $NAMESERVER"
    echo "prog: $PROG"
fi

if [ "$CLEANUP" -gt 0 ]; then
    cleanup_traffic $NS_NAME $IP $INTERFACE
    cleanup_nameserver $NS_NAME
    cleanup_ns $NS_NAME $IP
else
    setup_ns $NS_NAME $IP
    setup_nameserver $NS_NAME $NAMESERVER 
    setup_traffic $NS_NAME $IP $INTERFACE

    if [ -n "$PROG" ]; then
        cleanup() {
            cleanup_traffic $NS_NAME $IP $INTERFACE
            cleanup_nameserver $NS_NAME
            cleanup_ns $NS_NAME $IP
        }

        trap cleanup SIGINT SIGTERM
        ip netns exec $NS_NAME $PROG
        cleanup
    fi
fi

