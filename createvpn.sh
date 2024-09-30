#!/bin/bash
#SET UPDATE FILE VERSION
CURRENT_VERSION=4
echo 'SERVER_VERSION='$CURRENT_VERSION > v

#INSTALL REQUIREMENTS
apt --yes --allow-downgrades --allow-remove-essential --allow-change-held-packages update
apt-get --yes --allow-downgrades --allow-remove-essential --allow-change-held-packages install strongswan libcharon-extra-plugins libstrongswan-standard-plugins strongswan-pki moreutils iptables-persistent network-manager-strongswan

#GET CURRENT IP
ipaddress=$(wget -qO- icanhazip.com)

#SETUP VPN
FILE="$PWD/vpn-certs"
if [ ! -d "$FILE" ]; then
    mkdir vpn-certs
fi
cd vpn-certs
alias proj="cd vpn-certs"
ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem
chmod 600 server-root-key.pem
ipsec pki --self --ca --lifetime 3650 --in server-root-key.pem --type rsa --dn "C=US, O=Hasan, CN=Hasan" --outform pem > server-root-ca.pem
ipsec pki --gen --type rsa --size 4096 --outform pem > vpn-server-key.pem
ipsec pki --pub --in vpn-server-key.pem --type rsa | ipsec pki --issue --lifetime 1825 --cacert server-root-ca.pem --cakey server-root-key.pem --dn "C=US, O=Hasan, CN=$ipaddress" --san $ipaddress --flag serverAuth --flag ikeIntermediate --outform pem > vpn-server-cert.pem
sudo cp ./vpn-server-cert.pem /etc/ipsec.d/certs/vpn-server-cert.pem
sudo cp ./vpn-server-key.pem /etc/ipsec.d/private/vpn-server-key.pem
sudo chown root /etc/ipsec.d/private/vpn-server-key.pem
sudo chgrp root /etc/ipsec.d/private/vpn-server-key.pem
sudo chmod 600 /etc/ipsec.d/private/vpn-server-key.pem
sudo cp /etc/ipsec.conf /etc/ipsec.conf.original
echo '' | sudo tee /etc/ipsec.conf
echo -e "
config setup
    charondebug="ike 1, knl 1, cfg 0"
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
sed -i 's/sha2-truncbug=yes/sha2-truncbug=no/g' /etc/ipsec.conf
echo -e "
$ipaddress : RSA \"/etc/ipsec.d/private/vpn-server-key.pem\"
norsevpn : EAP \"Qect87Yj2EqsAWpX\"
" >> /etc/ipsec.secrets
sudo ipsec reload
sudo ufw disable
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
iptables -Z
sudo iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -p udp --dport  500 -j ACCEPT
sudo iptables -A INPUT -p udp --dport 4500 -j ACCEPT
sudo iptables -A FORWARD --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.10/24 -j ACCEPT
sudo iptables -A FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.10/24 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o eth0 -j MASQUERADE
sudo iptables -t mangle -A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.10/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
sudo iptables -A INPUT -j DROP
sudo iptables -A FORWARD -j DROP
sudo netfilter-persistent save
sudo netfilter-persistent reload
apt --yes --allow-downgrades --allow-remove-essential --allow-change-held-packages install firewalld
firewall-cmd --permanent --add-service="ipsec"
firewall-cmd --permanent --add-port=4500/udp
firewall-cmd --permanent --add-port=500/udp
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload
echo -e "net.ipv4.ip_forward=1\nnet.ipv4.conf.all.accept_redirects = 0\nnet.ipv4.conf.all.send_redirects = 0\nnet.ipv4.ip_no_pmtu_disc = 1\n" >> /etc/sysctl.conf
CERTSTR=`sudo cat ~/vpn-certs/server-root-ca.pem| grep -v CERTIFICATE`
CERTSTRNOBLANK=$(echo $CERTSTR | tr -d ' ')

#SETUP DNS-SERVERS
echo 'nameserver 8.8.8.8' > /etc/resolv.conf ; echo 'nameserver 8.8.4.4' >> /etc/resolv.conf
wget https://github.com/AccountOnetapp/gowalk-vpn-script/blob/main/check.sh -O check.sh ; chmod +x check.sh 
crontab -r
crontab -l | { cat; echo "* * * * * bash /root/check.sh >> vpn.log 2>&1"; } | crontab -
crontab -l | { cat; echo "* * * * * wget https://raw.githubusercontent.com/AccountOnetapp/gowalk-vpn-script/refs/heads/main/update.sh ; chmod +x update.sh ; bash update.sh >> update.log 2>&1"; } | crontab -

#PRINT CERTIFICATE
echo $CERTSTRNOBLANK
reboot
