#!/bin/bash

command -v iwgetid >/dev/null 2>&1
if [ $? -eq 0 ]; then
    SSID=`iwgetid -r`
else
    SSID=`netsh WLAN show interfaces | grep ' SSID' | awk '{ print $3 }'`
fi
echo $SSID
