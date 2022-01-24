#!/bin/bash

#Author	: Sagar Khandve
#Email		: i.sagarkhandve@gmail.com

# Install packages
opkg update
opkg install tor iptables-mod-extra
 
# Configure Tor client
cat << EOF > /etc/tor/custom
AutomapHostsOnResolve 1
AutomapHostsSuffixes .
VirtualAddrNetworkIPv4 172.16.0.0/12
VirtualAddrNetworkIPv6 fc00::/7
DNSPort 0.0.0.0:9053
DNSPort [::]:9053
TransPort 0.0.0.0:9040
TransPort [::]:9040
EOF
cat << EOF >> /etc/sysupgrade.conf
/etc/tor/custom
EOF
uci del_list tor.conf.tail_include="/etc/tor/custom"
uci add_list tor.conf.tail_include="/etc/tor/custom"
uci commit tor
/etc/init.d/tor restart

#Configure firewall to intercept LAN traffic. Disable LAN to WAN forwarding to avoid traffic leak. 
# Intercept TCP traffic
uci -q delete firewall.tcp_int
uci set firewall.tcp_int="redirect"
uci set firewall.tcp_int.name="Intercept-TCP"
uci set firewall.tcp_int.src="lan"
uci set firewall.tcp_int.dest_port="9040"
uci set firewall.tcp_int.proto="tcp"
uci set firewall.tcp_int.extra="--syn -m addrtype ! --dst-type LOCAL,BROADCAST"
uci set firewall.tcp_int.target="DNAT"
 
# Disable LAN to WAN forwarding
uci rename firewall.@forwarding[0]="lan_wan"
uci set firewall.lan_wan.enabled="0"
uci commit firewall
/etc/init.d/firewall restart

# DNS over Tor Configure firewall to intercept DNS traffic. 
# Intercept DNS traffic
uci -q delete firewall.dns_int
uci set firewall.dns_int="redirect"
uci set firewall.dns_int.name="Intercept-DNS"
uci set firewall.dns_int.src="lan"
uci set firewall.dns_int.src_dport="53"
uci set firewall.dns_int.proto="tcp udp"
uci set firewall.dns_int.target="DNAT"
uci commit firewall
/etc/init.d/firewall restart

#Redirect DNS traffic to Tor. 
# Enable DNS over Tor
/etc/init.d/dnsmasq stop
uci set dhcp.@dnsmasq[0].boguspriv="0"
uci set dhcp.@dnsmasq[0].rebind_protection="0"
uci set dhcp.@dnsmasq[0].noresolv="1"
uci -q delete dhcp.@dnsmasq[0].server
uci add_list dhcp.@dnsmasq[0].server="127.0.0.1#9053"
uci add_list dhcp.@dnsmasq[0].server="::1#9053"
uci commit dhcp
/etc/init.d/dnsmasq start

#Enable NAT6 to process IPv6 traffic when using dual-stack mode. 
# Install packages
opkg update
opkg install kmod-ipt-nat6
 
# Enable NAT6
cat << "EOF" > /etc/firewall.nat6
iptables-save -t nat \
| sed -e "
/\sMASQUERADE$/d
/\s[DS]NAT\s/d
/\s--match-set\s\S*/s//\06/
/,BROADCAST\s/s// /" \
| ip6tables-restore -T nat
EOF
cat << "EOF" >> /etc/sysupgrade.conf
/etc/firewall.nat6
EOF
uci -q delete firewall.nat6
uci set firewall.nat6="include"
uci set firewall.nat6.path="/etc/firewall.nat6"
uci set firewall.nat6.reload="1"
uci commit firewall
/etc/init.d/firewall restart
