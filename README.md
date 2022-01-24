[![License](https://img.shields.io/badge/License-MIT-blue)](#license "Go to license section")

### OpenWrt - Tor Router
1. Connect to OpenWrt router using ssh connection.
```shell
    ssh root@192.168.1.1
```
2. Clone this repository and `cd` into it and execute the script.
```shell
    git clone https://github.com/sagarkhandve/OpenWrt-TorRouter.git
    cd OpenWrt-TorRouter/
    chmod +x OpenWrt-TorRouter.sh
    sh OpenWrt-TorRouter.sh
 ```
3. Verify that you are using Tor.
```shell
    https://check.torproject.org/
```
4. Check your client public IP addresses.
```shell
   https://ipleak.net/
```
5. Make sure there is no DNS leak on the client side.
```shell
   https://dnsleaktest.com/
```
### Troubleshooting.    
1. Restart services.
```shell
   /etc/init.d/log restart; /etc/init.d/firewall restart; /etc/init.d/tor restart
```
2. Log and status.
```shell
   logread -e Tor; netstat -l -n -p | grep -e tor
```
3. Runtime configuration.
```shell
   pgrep -f -a tor
   iptables-save -c; ip6tables-save -c; ipset list
```
4. Persistent configuration.
```shell
   uci show firewall; uci show tor; grep -v -r -e "^#" -e "^$" /etc/tor
```
