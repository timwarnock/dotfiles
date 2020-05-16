#!/bin/bash
#
: ${DISPLAY:=":0"}
export DISPLAY
export PATH=$PATH:~/bin
export XDG_RUNTIME_DIR=/run/user/`id -u`


##
## LEFT | RIGHT | CENTER | SET | RESET
BASEDIR=$(dirname "$0")
LAST_LAST=$BASEDIR/.gather.last

CMD="SET"
case "${1^^}" in
    "RIGHT" | "R") CMD="RIGHT" ;;
    "CENTER" | "C") CMD="CENTER" ;;
    "LEFT" | "L") CMD="LEFT" ;;
    "RESET") echo "reset is not implemented yet";
        CMD="LEFT" ;;
    *) echo "set is not implemented yet";
        CMD="LEFT" ;;
esac


##
## get full desktop width (across all displays)
WIDTH=$(wmctrl -d | awk '{ print $4 }' | awk -Fx '{ print $1 }')

##
## move all windows LEFT | RIGHT | CENTER
WIN_POS=$(wmctrl -lG | grep -v 'Desktop$' | awk '{ print($1, $3, $4, $5, $6) }')
echo "$WIN_POS" | while read -r WIN_ID WIN_X WIN_Y WIN_W WIN_H; do
  COORDS="0,0"
  if [ "$CMD" = "RIGHT" ]; then
    let X_COORD=$(( $WIDTH - $WIN_W ))
    COORDS="$X_COORD,0"
  elif [ "$CMD" = "CENTER" ]; then
    let CENTER_X=$(( $WIDTH / 2 ))
    let W_HALF=$(( $WIN_W / 2 ))
    let X_COORD=$(( $CENTER_X - $W_HALF ))
    COORDS="$X_COORD,0"
  fi
  wmctrl -ir $WIN_ID -e 0,$COORDS,-1,-1
done

