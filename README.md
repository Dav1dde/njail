Njail
=====

Simple wrapper to manage network namespaces `ip netns`, useful to run certain programs through a vpn or completly disallow any network access.

## Example

### Drop all traffic

```
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ./njail.sh -i enp+ -n test -q
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ip netns exec test pin 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=43 time=34.2 ms
^C
--- 8.8.8.8 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 34.232/34.232/34.232/0.000 ms
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ip netns exec test curl -I google.com 
HTTP/1.1 302 Found
Cache-Control: private
[...]
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ./dropall.sh test
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ip netns exec test ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
ping: sendmsg: Operation not permitted
^C
--- 8.8.8.8 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1011ms
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ip netns exec test curl -I google.com 
curl: (6) Could not resolve host: google.com
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ./njail.sh -i enp+ -n test -c -q 
```
