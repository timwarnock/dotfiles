#! /bin/bash
COLS=$(tput cols);
MAX_HIST=`eval printf '\#%.0s' {1..$COLS}; echo;`

while read datain
do
  if [ -n "$datain" ]; then
    echo -n ${MAX_HIST:0:$datain}
    if [ $datain -gt $COLS ]; then
      printf "\r$datain\n"
    else
      printf "\n"
    fi
  fi
done < "${1:-/dev/stdin}"

