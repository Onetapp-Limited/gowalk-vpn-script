#!/bin/bash
export PATH="$PATH:/usr/sbin"
if service ipsec status | grep 'failed to establish\|unable to install\|failed to establish CHILD_SA\|unable to install IPsec policies\|charon refused to be started'; then
    service ipsec restart
    echo `date +"%Y-%m-%d %T"` 'Ipsec restarted'
fi