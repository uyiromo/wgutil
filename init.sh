#!/bin/bash

source wgenv

if [[ $# != 2 ]]
then
    echo "Usage: $0 <vpn-endpoint>"
fi
echo $1 > $WG0ENDPOINT

# Enable packet forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1


apt install qrencode
apt install wireguard wireguard-tools

# Generate the server-side keys
genkeys $SERV_PRIVATEKEY $SERV_PUBLICKEY $SERV_PRESHAREDKEY

# wg0.conf
cat <<_EOF_ > $WG0CONF
[Interface]
PrivateKey = $( cat $SERV_PRIVATEKEY )
Address = $WIREGUARD_SUBNET.1/24
ListenPort = 51820
Table = off

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;iptables -A FORWARD -o wg0 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE;iptables -D FORWARD -o wg0 -j ACCEPT

_EOF_

# enable wg0
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# initialize peers
echo 2 > $PEERS_DB
