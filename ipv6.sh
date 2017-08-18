#!/bin/bash

#Install the package kmod-ipt-nat6
opkg update && opkg install kmod-ipt-nat6

#Change the first letter of the "IPv6 ULA Prefix" from f to d
uci set network.globals.ula_prefix="$(uci get network.globals.ula_prefix | sed 's/^./d/')"
uci commit network

#Set the DHCP server to "Always announce default router"
uci set dhcp.lan.ra_default='1'
uci commit dhcp

#Add an init script for NAT6 by creating a new file /etc/init.d/nat6 and paste the code from the section Init Script into it
cp -f nat6 /etc/init.d/nat6

#Make the script executable and enable it
chmod +x /etc/init.d/nat6
/etc/init.d/nat6 enable

#In addition, you may now disable the default firewall rule "Allow-ICMPv6-Forward" since it's not needed when masquerading is enabled
uci set firewall.@rule["$(uci show firewall | grep 'Allow-ICMPv6-Forward' | cut -d'[' -f2 | cut -d']' -f1)"].enabled='0'
uci commit firewall

#Edit the /etc/sysctl.d/local.conf file
sed -i -e 's|net.ipv6.conf.default.forwarding=1|net.ipv6.conf.default.forwarding=2|' /etc/sysctl.conf
sed -i -e 's|net.ipv6.conf.all.forwarding=1|net.ipv6.conf.all.forwarding=2|' /etc/sysctl.conf
echo "net.ipv6.conf.default.accept_ra=2" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_ra=2" >> /etc/sysctl.conf

#Edit /etc/firewall.user
echo "ip6tables -t nat -I POSTROUTING -s $(uci get network.globals.ula_prefix) -j MASQUERADE" >> /etc/firewall.user

#Reboot to to apply the config
echo "Congfig finished!"
echo "Device is rebooting!"
reboot
