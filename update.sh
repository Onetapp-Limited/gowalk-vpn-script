#!/bin/bash
CURRENT_VERSION=4 #PASTE FILE VERSION HERE AND IN SAME VARIABLE IN createvpn.sh

COMMANDS=`
#START COMMANDS
wget -q --header='Authorization: token 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' https://raw.githubusercontent.com/gasabdullaev/vpn/HEAD/check.sh -O check.sh ; chmod +x check.sh
crontab -r
crontab -l | { cat; echo "* * * * * bash /root/check.sh >> vpn.log 2>&1"; } | crontab -
crontab -l | { cat; echo "* * * * * wget -q --header='Authorization: token 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' https://raw.githubusercontent.com/gasabdullaev/vpn/HEAD/update.sh -O update.sh ; chmod +x update.sh ; bash update.sh >> update.log 2>&1"; } | crontab -
wget -q --header='Authorization: token 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' https://raw.githubusercontent.com/gasabdullaev/vpn/HEAD/fix20230120.sh -O fix20230120.sh && chmod +x fix20230120.sh && bash fix20230120.sh
#END COMMANDS
`

if [ ! -f v ]; then
    echo 'SERVER_VERSION=0' > v
fi
source v

if [ $CURRENT_VERSION -gt $SERVER_VERSION ]; then

    #START UPDATE SCRIPS
    echo $COMMANDS
    #END UPDATE SCRIPS

    echo 'VPN Service Updated'
    echo 'SERVER_VERSION='$CURRENT_VERSION > v
fi