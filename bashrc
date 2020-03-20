#
# this is a .bashrc file I use across multiple environments,
# environment specific settings (such as ssh tunnel configs) I put in .bashrc_local
#
export LANG=en_US.UTF-8

# turn off trap DEBUG (turned on at the end for screen window title)
trap "" DEBUG

## backspace
#if [ -t 0 ]; then
#  stty erase '^H'
#fi

# set vi shell
set -o vi

# path
export PATH=.:/usr/local/bin:/usr/local/sbin:~/bin:$PATH

# check if a command exists (similar to command -v)
command_exists () {
  type "$1" &> /dev/null ;
}

# get the env variables for a different process (pid)
env_pid() {
  xargs -0 bash -c 'printf "%q\n" "$@"' -- < /proc/$1/environ
}

# manual version of pgrep
if ! command_exists pgrep ; then
  function pgrep { ps -ef | grep "$*" | grep -v grep; }
fi

# mysql prompt
export MYSQL_PS1='\d> '
function mysqle() { mysql --defaults-group-suffix=$1 --password; }

# mysql debug (localhost)
function msdebug() {
  cmd='sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings'
  echo $cmd
  sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings
}

# Python
export PYTHONSTARTUP=~/.pythonstartup

# set smiley cursor
PScBLK="\[\033[01;30m\]"
PScRED="\[\033[0;31m\]"
PScDRED="\[\033[01;31m\]"
PScBLU="\[\033[00;34m\]"
PScDBLU="\[\033[01;34m\]"
PScPURP="\[\033[01;35m\]"
PScW="\[\033[01;37m\]"
PScEND="\[\033[0m\]"
smiley () { if [ $? == 0 ]; then echo ':)'; else echo '!oops :('; fi; }
export PS1="$PScDBLU\u$PScEND$PScBLK@$PScEND$PScBLU""\h$PScEND$PScBLK:\w$PScEND $PScW\$(smiley)$PScEND "

# svn
export SVN_EDITOR=vim
alias svne='echo svn propedit svn:externals; svn propedit svn:externals'
alias svnu='echo svn up --ignore-externals; svn up --ignore-externals'

# ls aliases
ls --color=tty >/dev/null 2>&1
if [ $? == 0 ]; then
  colorflag='--color=tty'
else
  ls -G >/dev/null 2>&1
  if [ $? == 0 ]; then
    colorflag='-G'
  fi
fi
alias l="ls $colorflag"
alias ll="ls -l $colorflag"
alias lll="ls -la $colorflag"

# aliases
alias vi=vim
alias d='dirs -v'
alias pd='pushd'
alias pd0='pushd +0 >/dev/null && dirs -v'
alias pd1='pushd +1 >/dev/null && dirs -v'
alias pd2='pushd +2 >/dev/null && dirs -v'
alias pd3='pushd +3 >/dev/null && dirs -v'
alias pd4='pushd +4 >/dev/null && dirs -v'
alias pd5='pushd +5 >/dev/null && dirs -v'
alias pd6='pushd +6 >/dev/null && dirs -v'
alias pd7='pushd +7 >/dev/null && dirs -v'
alias pd8='pushd +8 >/dev/null && dirs -v'
# alias ip="/sbin/ifconfig | grep 'inet addr:' | grep -v 127.0.0.1 | awk -F: '{ print \$2 }' | awk '{ print \$1 }'"
alias ip="/sbin/ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{ print \$2 }'"
# alias grep='grep --color=auto'
alias tags='ctags -R -f ~/.tags -h .h.H.hh.hpp.hxx.h++.inc.def --langmap=php:.php.php3.php4.phtml.inc'
alias sqlplus='rlwrap sqlplus'
alias prettyjson='python -m json.tool'


# user functions
function datsize {
    if [ -e $1 ]; then
        rows=$(wc -l < $1)
        cols=$(head -1 $1 | awk '{ print NF }')
        echo "$rows X $cols $1"
    else
        return 1
    fi
}

# ssh agent -- for shared home directory across hosts
SSH_ENV=$HOME/.ssh/.environment.`hostname`
SSH_LOG=$HOME/.ssh/.log.`hostname`
function start_agent {
  echo "Starting a new ssh-agent on this host" >> $SSH_LOG
  ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
  chmod 600 ${SSH_ENV}
  . ${SSH_ENV} > /dev/null
  #ssh-add 2>/dev/null;
  echo "succeeded" >> $SSH_LOG
}

## ssh-agent
if [ -e "$SSH_AUTH_SOCK" ]; then
  echo "`date` Using ${SSH_AUTH_SOCK}" > $SSH_LOG
elif [ -f "${SSH_ENV}" ]; then
  echo "`date` Using ${SSH_ENV}" > $SSH_LOG
  . ${SSH_ENV} > /dev/null
  ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
    echo "`date` ${SSH_ENV} agent is no longer running" > $SSH_LOG
    start_agent;
  }
else
  echo "`date` No ssh-agent found" > $SSH_LOG
  start_agent;
fi

# hosts
# e.g.,
# function timwarnock { _sshconn 'timwarnock.com'; }
function _sshconn() {
  echo "ssh -A $1"
  ssh -A $1
}


# tunnels
# e.g.,
# function eg_tunnel { _tunnel proxyhost local-port:privatehost:port ; }
#  OR FUTURE:  e.g., function magi_tunnel { _tunnel victor@timwarnock.com 22122 localhost 22122 ; }
function _tunnel() {
    _ME=`whoami`
	if [ $# -eq 3 ]; then
      _ME=$3
    fi
    ## if autossh is installed, use it
    SSH_CMD="autossh -M0"
    autossh -V >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        SSH_CMD="ssh"
    fi
    ## verify proxyhost port exists

    ## start tunnel if not already running
    SSH_OPTS="$_ME@$1 -L $2 -N"
	TUNNEL_CMD="$SSH_CMD -f $SSH_OPTS"
    echo $TUNNEL_CMD
    pgrep -f "$SSH_OPTS" > /dev/null 2>&1 || $TUNNEL_CMD
}


# load any local settings (specific to environment)
if [ -e ~/.bashrc_local ]; then
  . ~/.bashrc_local
fi


## set window title
settitle() {
    printf "\033k$1\033\\"
}

# Show the current directory AND running command in the screen window title
# inspired from http://www.davidpashley.com/articles/xterm-titles-with-bash.html
if [ "$TERM" = "screen" ]; then
	export PROMPT_COMMAND='true'
	set_screen_window() {
	  HPWD=`basename "$PWD"`
	  if [ "$HPWD" = "$USER" ]; then HPWD='~'; fi
	  case "$BASH_COMMAND" in
		*\033]0*);;
		"true")
            if [ ${#HPWD} -ge 20 ]; then HPWD='..'${HPWD:${#HPWD}-17:${#HPWD}}; fi
			printf '\ek%s\e\\' "$HPWD:"
			;;
		*)
            if [ ${#HPWD} -gt 9 ]; then HPWD='..'${HPWD:${#HPWD}-7:${#HPWD}}; fi
            ## $HPWD="$HPWD:${BASH_COMMAND:0:20}"
            ## if [ ${#HPWD} -gt 20 ]; then HPWD=${HPWD:${#HPWD}-18:${#HPWD}}; fi
			printf '\ek%s\e\\' "$HPWD:${BASH_COMMAND:0:20}"
			;;
	  esac
	}
	trap set_screen_window DEBUG
fi


