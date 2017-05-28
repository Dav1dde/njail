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

### Route traffic through VPN

```
~/workspaces/bash/njail(master) » sudo ./njail.sh -i enp+ -n vpn -q
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ./vpn.sh -n vpn -a "185.100.84.135/32,185.100.84.244/32,185.100.84.245/32,185.100.84.247/32,185.100.84.246/32" -c "/etc/openvpn/client/romania_bucharest-aes256-udp.conf" -d 8.8.8.8
Sun May 28 12:26:30 2017 OpenVPN 2.4.2 x86_64-unknown-linux-gnu [SSL (OpenSSL)] [LZO] [LZ4] [EPOLL] [PKCS11] [MH/PKTINFO] [AEAD] built on May 11 2017
Sun May 28 12:26:30 2017 library versions: OpenSSL 1.1.0e  16 Feb 2017, LZO 2.10
Sun May 28 12:26:30 2017 Outgoing Control Channel Authentication: Using 512 bit message hash 'SHA512' for HMAC authentication
Sun May 28 12:26:30 2017 Incoming Control Channel Authentication: Using 512 bit message hash 'SHA512' for HMAC authentication
Sun May 28 12:26:30 2017 TCP/UDP: Preserving recently used remote address: [AF_INET]185.100.84.244:50000
Sun May 28 12:26:30 2017 Socket Buffers: R=[212992->212992] S=[212992->212992]
Sun May 28 12:26:30 2017 UDP link local: (not bound)
[...]
------------------------------------------------------------
~/workspaces/bash/njail(master) » curl ifconfig.co/country
Austria
------------------------------------------------------------
~/workspaces/bash/njail(master) » sudo ip netns exec vpn curl ifconfig.co/country
Romania
```
