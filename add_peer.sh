#!/bin/bash

source wgenv

# Get peer id
id=$(( $( cat $PEERS_DB ) ))
peer_ip="$WIREGUARD_SUBNET.$id"


PEERDIR="$CONFDIR/peer$id"
PEER_PRIVATEKEY=$PEERDIR/privatekey
PEER_PUBLICKEY=$PEERDIR/publickey
PEER_PRESHAREDKEY=$PEERDIR/presharedkey

PEERCONF=$PEERDIR/peer.conf
PEERCONF_QRIMG=$PEERDIR/peer.conf.png

# Generate the peer-side keys
mkdir -p $PEERDIR
genkeys $PEER_PRIVATEKEY $PEER_PUBLICKEY $PEER_PRESHAREDKEY


# Append the peer config
cat << _EOF_ >> $WG0CONF
[Peer]
PublicKey= $( cat $PEER_PUBLICKEY )
PresharedKey = $( cat $PEER_PRESHAREDKEY )
AllowedIPs = $peer_ip/32

_EOF_


# Generate the peer config
cat << _EOF_ > $PEERCONF
[Interface]
PrivateKey = $( cat $PEER_PRIVATEKEY )
Address = $peer_ip
DNS = 8.8.8.8

[Peer]
PublicKey = $( cat $SERV_PUBLICKEY )
PresharedKey = $( cat $PEER_PRESHAREDKEY )
EndPoint = $( cat $WG0ENDPOINT )
AllowedIPs = 0.0.0.0/0, ::0/0
_EOF_

# relaunch wg0
wg-quick down wg0
wg-quick up wg0

# Increment the peer id
id=$(( $id + 1 ))
echo $id > $PEERS_DB

qrencode -t ansiutf8 -r $PEERCONF
qrencode -t png -r $PEERCONF -o $PEERCONF_QRIMG


# notification
python3 ./smtp.py "wgutil: New WireGuard Peer ($peer_ip)" $PEERCONF $PEERCONF_QRIMG
