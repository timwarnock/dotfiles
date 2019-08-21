#! /bin/bash
COLS=$(tput cols);
MAX_HIST=`eval printf '\#%.0s' {1..$COLS}; echo;`



## set title (for tmux and screen
settitle() {
  printf "\033k$1\033\\"
}


while read datain
do
  if [ -n "$datain" ]; then
    settitle "mon($datain)"
    echo -n ${MAX_HIST:0:$datain}
    if [ $datain -gt $COLS ]; then
      printf "\r$datain\n"
    else
      printf "\n"
    fi
  fi
done < "${1:-/dev/stdin}"

