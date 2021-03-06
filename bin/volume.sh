#!/bin/bash

PERCENT="50"
## make sure $1 is an integer (if it exists)
if [ $# -eq 1 -a "$1" -eq "$1" ] 2>/dev/null; then
  PERCENT=$1
  if [[ "$PERCENT" == *\% ]]; then
    PERCENT="${PERCENT::-1}"
  fi
fi

## make sure PERCENT is a valid integer
if [ ! $PERCENT -ge 0 -o ! $PERCENT -le 100 ]; then
  echo "volume must be between 0 and 100, defaulting to 50%"
  PERCENT="50"
fi



export PULSE_RUNTIME_PATH="/run/user/$(id -u)/pulse/"
SINK=`pacmd list-sinks | grep 'index:' | awk -F: '{print $2}'`
#pactl -- set-sink-volume 0 "$PERCENT%"
for _sink in $SINK; do
  echo "attempting to set volume (sink:$_sink) to $PERCENT%"
  pactl set-sink-volume $_sink "$PERCENT%"
done
