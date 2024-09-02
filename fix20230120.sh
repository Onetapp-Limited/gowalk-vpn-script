#!/bin/bash
echo "Fix IPSEC SA policy for duplicates"
echo "----------------------------------"
echo -n " - getting leftid from old config ... "
ipaddress=$(cat /etc/ipsec.conf | grep leftid | cut -d '=' -f2)
echo "$ipaddress"
echo -n " - updating ipsec config ... "
echo -ne | sudo tee /etc/ipsec.conf 2>/dev/null
echo -e "
config setup
    charondebug=\"ike 1, knl 1, cfg 0\"
    uniqueids=never
conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    ike=aes256-sha256-modp1024,aes256-sha256-modp2048, aes256-aes128-sha1-modp1024-3des!
    esp=aes256-sha256-sha1-3des!
    dpdaction=clear
    dpddelay=14400s
    rekey=no
    lifetime=24h
    left=%any
    leftid=$ipaddress
    leftcert=/etc/ipsec.d/certs/vpn-server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-mschapv2
    rightdns=1.1.1.1,1.0.0.1
    rightsourceip=10.10.10.0/24
    rightsendcert=never
    eap_identity=%identity
" >> /etc/ipsec.conf
echo "done"
echo -n " - reloading ipsec/charon service ... "
sudo service ipsec reload >>/dev/null 2>&1
echo "done"
echo "----------------------------------"
echo "All done!"

