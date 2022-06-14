#!/bin/bash


sed -i 's/net.ipv4.ip_forward.*/net.ipv4.ip_forward=1/g' /etc/sysctl.d/50-security-hardening.conf
sysctl -w net.ipv4.ip_forward=1

rm -f /etc/systemd/network/99-dhcp-en.network

cat > /etc/systemd/network/11-static-eth1.network << EOF
[Match]
Name=eth1

[Network]
Address=10.10.0.1/24
EOF

cat > /etc/systemd/network/12-static-eth2.network << EOF
[Match]
Name=eth2

[Network]
Address=10.20.0.1/24
EOF

chmod 655 /etc/systemd/network/*
systemctl restart systemd-networkd

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth1 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -j ACCEPT
if [ ${SETUP_DNS_SERVER} -eq 1 ]; then
    iptables -A INPUT -i eth0 -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i eth1 -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -i eth2 -p udp --dport 53 -j ACCEPT
fi
iptables-save > /etc/systemd/scripts/ip4save

systemctl restart iptables
