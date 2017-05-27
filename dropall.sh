#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "root required";
    exit
fi

if [ -z "$1" ]; then
    echo "no namespace given"
    exit 2;
fi

ns_name="$1"
ns_name0="${ns_name}0"
ns_name1="${ns_name}1"

ipt() {
    ip netns exec $ns_name iptables "$@"
}

ipt -F
ipt -P INPUT DROP
ipt -P OUTPUT DROP
ipt -P FORWARD DROP
