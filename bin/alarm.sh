#!/bin/bash
#
# crontab, set the alarm (for example) on weekdays at 7am
# 0 7 * * 1-5 alarm.sh 60 >/dev/null 2>&1
#
export DISPLAY=":0"
export PATH=$PATH:~/bin

WAKEUP_FILE=/home/twarnock/Music/0_playlist/Classical.xspf
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
  echo "Beginning wake up sequence with low volume"
  volume.sh 20
  pkill vlc
  sleep 1 #allow vlcrc to cleanup
  nohup vlc -Z $WAKEUP_FILE >/dev/null 2>&1 &
else
  echo "Idle for 0 minutes, no need for alarm"
fi

## now that music is on, turn on display
sleep 1 #audio is active, which should disable screensaver
xset -display $DISPLAY dpms force on


## slowly increase volume
# if idle time is 0, then pause music and exit
# if timeout, ALARM and exit
STILL_RUNNING=1
CURR_VOL=20
VOL30_TS=$(( $START_TS + $WAIT_SEC/4 ))
VOL40_TS=$(( $START_TS + $WAIT_SEC/3 ))
VOL50_TS=$(( $START_TS + $WAIT_SEC/2 ))
END_TS=$(( $START_TS + $WAIT_SEC ))
while (( $STILL_RUNNING == 1 )); do
  NOW_TS=`date +"%s"`
  if (( `display.sh -m` == 0 )); then
    echo "Idle time now 0 minutes, pausing music and exiting"
    vlcrc pause
    STILL_RUNNING=0
  elif (( $NOW_TS >= $END_TS )); then
    echo "Max time reached, sounding alarm and exiting"
    pkill vlc
    volume.sh 60
    nohup vlc -Z $ALARM_FILE >/dev/null 2>&1 &
    STILL_RUNNING=0
  elif (( $NOW_TS >= $VOL50_TS && $CURR_VOL < 50 )); then
    echo "No activity in $(( $WAIT_SEC/2 / 60 )) minutes, raising volume"
    CURR_VOL=50
    volume.sh 50
  elif (( $NOW_TS >= $VOL40_TS && $CURR_VOL < 40 )); then
    echo "No activity in $(( $WAIT_SEC/3 / 60 )) minutes, raising volume"
    CURR_VOL=40
    volume.sh 40
  elif (( $NOW_TS >= $VOL30_TS && $CURR_VOL < 30 )); then
    echo "No activity in $(( $WAIT_SEC/4 / 60 )) minutes, raising volume"
    CURR_VOL=30
    volume.sh 30
  fi
  sleep 0.5
done

exit
