#!/bin/bash

#public_ip4=`dig +short myip.opendns.com @resolver1.opendns.com`
public_ip4=`curl -s https://ipinfo.io/ip`
command -v ipconfig >/dev/null 2>&1
if [ $? -eq 0 ]; then
    private_ip4=`ipconfig | grep "IPv4 Address" | awk '{print $NF}'`
else
    private_ip4=`hostname -I`
fi

echo $private_ip4
echo $public_ip4
