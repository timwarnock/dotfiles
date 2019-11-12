#!/bin/bash

##
## get a list of all windows (not the Desktop itself)
WIN_IDS=$(wmctrl -l | grep -v 'Desktop$' | awk '{ print $1 }')

##
## move each window LEFT 0,0
for winid in $WIN_IDS; do
  wmctrl -ir $winid -e 0,0,0,-1,-1
done

