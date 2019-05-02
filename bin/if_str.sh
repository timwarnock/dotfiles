#!/bin/bash

iwconfig 2>/dev/null | grep "Quality=" | awk '{ print $2 }' | awk -F= '{ print "Signal: " $2 }'

awk '/wlx10/ {i++; rx[i]=$2; tx[i]=$10}; END{print "RX: " (rx[2]-rx[1])/512 " kB/s\nTX: " (tx[2]-tx[1])/512 " kB/s" }'  <(cat /proc/net/dev; sleep 0.5; cat /proc/net/dev)
