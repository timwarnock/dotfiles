#!/bin/bash
#
# crontab, set the alarm (for example) on weekdays at 7am
# 0 7 * * 1-5 alarm.sh 60 >/dev/null 2>&1
#
: ${DISPLAY:=":0"}
export DISPLAY
export PATH=$PATH:~/bin
export XDG_RUNTIME_DIR=/run/user/`id -u`

WAKEUP_FILE=/home/twarnock/Music/0_playlist/chakras.xspf
ALARM_FILE=/home/twarnock/Music/0_playlist/PunkFunk.xspf

##
## set how long to wait
START_TS=`date +"%s"`
WAIT_MIN=60
if [ $# -gt 0 ]; then
  if (( $1 > 0 && $1 <= 180 )); then
    WAIT_MIN=$1
  fi
fi
WAIT_SEC=$(( $WAIT_MIN * 60 ))





## play music at low volume
if (( `display.sh -m` > 0 )); then
  echo "Beginning wake up sequence, display on, and low volume"
  display.sh on
  pkill vlc
  volume.sh 30
  nohup vlc -Z $WAKEUP_FILE >/dev/null 2>&1 &
else
  echo "Idle for 0 minutes, no need for alarm"
fi


## slowly increase volume
# if idle time is 0, then pause music and exit
# if timeout, ALARM and exit
STILL_RUNNING=1
CURR_VOL=30
VOL50_TS=$(( $START_TS + $WAIT_SEC/4 ))
VOL65_TS=$(( $START_TS + $WAIT_SEC/3 ))
VOL80_TS=$(( $START_TS + $WAIT_SEC/2 ))
END_TS=$(( $START_TS + $WAIT_SEC ))
while (( $STILL_RUNNING == 1 )); do
  NOW_TS=`date +"%s"`
  if (( `display.sh -m` == 0 )); then
    echo "Idle time now 0 minutes, pausing music and exiting"
    vlcrc pause || pkill vlc
    STILL_RUNNING=0
  elif (( $NOW_TS >= $END_TS )); then
    echo "Max time reached, sounding alarm and exiting"
    pkill vlc
    volume.sh 80
    nohup vlc -Z $ALARM_FILE >/dev/null 2>&1 &
    STILL_RUNNING=0
  elif (( $NOW_TS >= $VOL80_TS && $CURR_VOL < 80 )); then
    echo "No activity in $(( $WAIT_SEC/2 / 60 )) minutes, raising volume"
    CURR_VOL=80
    volume.sh 80
  elif (( $NOW_TS >= $VOL65_TS && $CURR_VOL < 65 )); then
    echo "No activity in $(( $WAIT_SEC/3 / 60 )) minutes, raising volume"
    CURR_VOL=65
    volume.sh 65
  elif (( $NOW_TS >= $VOL50_TS && $CURR_VOL < 50 )); then
    echo "No activity in $(( $WAIT_SEC/4 / 60 )) minutes, raising volume"
    CURR_VOL=50
    volume.sh 50
  fi
  sleep 0.5
done

exit
