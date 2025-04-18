#!/bin/bash
#
# crontab, if idle for over 90 minutes then turn off display (check every 5 minutes)
# */5 * * * * display.sh screensave 90 >/dev/null 2>&1
#
: ${DISPLAY:=":1"}
export DISPLAY
export XDG_RUNTIME_DIR=/run/user/`id -u`

#
# get the idle time
LASTON=~/bin/.display.sh.laston
idleS=$((`xprintidle` / 1000))
idleM=$(($idleS / 60))
## if LASTON file exists, use that only if it's smaller than xprintidle
if [[ -e "$LASTON" ]]; then
  lastonS=$(( (`date +"%s"` - `cat $LASTON`) ))
  if [[ $lastonS -lt $idleS ]]; then
    idleS=$lastonS
    idleM=$(( $lastonS / 60 ))
  fi
fi


#
# check if any audio is playing
IS_AUDIO="Off"
#cat /proc/asound/card*/pcm*/sub*/status | grep RUNNING 2>&1 >/dev/null
pacmd list-sink-inputs | grep RUNNING 2>&1 >/dev/null
if [ $? -eq 0 ]; then
  IS_AUDIO="On"
fi


#
# if idle too long, shut off screen IFF no audio is playing
if [ $# -eq 2 -a "$1" == "screensave" ]; then
  screenM=$2
  if [ $idleM -ge $screenM -a "$IS_AUDIO" == "Off" ]; then
    xset -display $DISPLAY dpms force off
    rm -rf $LASTON
  else
    echo "not going to screensave. Audio: $IS_AUDIO  Idle: $idleM minutes"
  fi
#
# force display OFF
elif [ $# -eq 1 -a "$1" == "off" ]; then
  xset -display $DISPLAY dpms force off
  rm -rf $LASTON
# force display ON
elif [ $# -eq 1 -a "$1" == "on" ]; then
  echo `date +"%s"` >$LASTON
  xset -display $DISPLAY dpms force on
#
# print the idle time in minutes
elif [ $# -eq 1 -a "$1" == "-m" ]; then
  echo $idleM
#
# just print the idle time
else
  printf "Audio: %s  Idle: %dm%02ds\n" $IS_AUDIO $idleM $(($idleS % 60))
fi
