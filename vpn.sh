#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "root required";
    exit
fi

usage_and_die() {
    if [ -n "$1" ]; then
        echo "$1 required";
    fi
    echo "usage: -n NAMESPACE -a VPN_IP -c VPN_CONFIG -i VPN_INTERFACE -r VETH_IP -d DNS_IP"
    echo "  -n NAMESPACE           the namespace name"
    echo "  -a VPN_IP              IP of the VPN server"
    echo "  -c VPN_CONFIG          configuration file for the vpn"
    echo "  -i VPN_INTERFACE       interface name of the vpn connection, defaults to tun0"
    echo "  -r VETH_IP             ip of the VETH adapter, same as with njail, defaults to 10.200.200"
    echo "  -d DNS_IP              dns server ip range, like 8.8.8.8/32"
    exit 2
}

NS_NAME=""
VPN_IP=""
VPN_CONFIG=""
VPN_INTERFACE="tun0"
IP="10.200.200"
DNS_IP=""

while getopts "hn:a:c:i:r:d:" opt; do
    case $opt in
        h)
            usage_and_die;;
        n)
            NS_NAME=$OPTARG;;
        a)
            VPN_IP=$OPTARG;;
        c)
            VPN_CONFIG=$OPTARG;;
        i)
            VPN_INTERFACE=$OPTARG;;
        r)
            IP=$OPTARG;;
        d)
            DNS_IP=$OPTARG;;
        \?)
            usage_and_die;;
    esac
done

if [ -z "$NS_NAME" ]; then usage_and_die "namespace"; fi
if [ -z "$VPN_IP" ]; then usage_and_die "vpn ip"; fi
if [ -z "$VPN_CONFIG" ]; then usage_and_die "vpn configuration"; fi

NS_NAME0="${NS_NAME}0"
NS_NAME1="${NS_NAME}1"

ipt() {
    ip netns exec $NS_NAME iptables "$@"
}

ipt -A OUTPUT -o $VPN_INTERFACE -j ACCEPT
ipt -A OUTPUT -o $NS_NAME1 -d  $VPN_IP -j ACCEPT
ipt -A OUTPUT -o $NS_NAME1 -d $IP.1  -j ACCEPT
ipt -A OUTPUT -o $NS_NAME1 -d $IP.2  -j ACCEPT
if [ -n "$DNS_IP" ]; then
    ipt -A OUTPUT -d $DNS_IP -p udp -m udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
    ipt -A OUTPUT -d $DNS_IP -p tcp -m tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
fi
ipt -A OUTPUT -o $NS_NAME1 -j DROP 


exec ip netns exec $NS_NAME openvpn --nobind --config ${VPN_CONFIG}

