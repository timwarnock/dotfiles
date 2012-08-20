
## backspace
if [ -t 0 ]; then
  stty erase '^H'
fi

# set vi shell
set -o vi

# path
export PATH=.:/usr/local/bin:~/bin:$PATH

# check if a command exists (similar to command -v)
command_exists () {
    type "$1" &> /dev/null ;
}

# manual version of pgrep
if ! command_exists pgrep ; then
  function pgrep { ps -ef | grep "$*" | grep -v grep; }
fi

# mysql prompt
export MYSQL_PS1='\d> '

# mysql debug (localhost)
function msdebug() {
  cmd='sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings'
  echo $cmd
  sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings
}

# Python
export PYTHONSTARTUP=~/.pythonstartup

# set smiley cursor
PScBLK="\e[01;30m\]"
PScRED="\e[0;31m\]"
PScDRED="\e[01;31m\]"
PScBLU="\e[00;34m\]"
PScDBLU="\e[01;34m\]"
PScPURP="\e[01;35m\]"
PScW="\e[01;37m\]"
PScEND="\e[0m\]"
smiley () { if [ $? == 0 ]; then echo ':)'; else echo '!oops :('; fi; }
export PS1="$PScDBLU\u$PScEND$PScBLK@$PScEND$PScBLU""laptop$PScEND$PScBLK:\w$PScEND $PScW\$(smiley)$PScEND "

# svn
export SVN_EDITOR=vim
alias svne='svn propedit svn:externals'

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
alias pd0='pushd +0 >/dev/null ; dirs -v'
alias pd1='pushd +1 >/dev/null ; dirs -v'
alias pd2='pushd +2 >/dev/null ; dirs -v'
alias pd3='pushd +3 >/dev/null ; dirs -v'
alias pd4='pushd +4 >/dev/null ; dirs -v'
# alias ip="/sbin/ifconfig | grep 'inet addr:' | grep -v 127.0.0.1 | awk -F: '{ print \$2 }' | awk '{ print \$1 }'"
alias ip="/sbin/ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{ print \$2 }'"
# alias grep='grep --color=auto'
alias tags='ctags -R -f ~/.tags -h .h.H.hh.hpp.hxx.h++.inc.def --langmap=php:.php.php3.php4.phtml.inc'
alias sqlplus='rlwrap sqlplus'


# ssh agent -- for shared home directory across hosts
SSH_ENV=$HOME/.ssh/.environment.`hostname`
SSH_LOG=$HOME/.ssh/.log.`hostname`
function start_agent {
  echo "Starting a new ssh-agent on this host" >> $SSH_LOG
  ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
  chmod 600 ${SSH_ENV}
  . ${SSH_ENV} > /dev/null
  ssh-add;
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
function _sshconn() {
  echo "ssh -A $1"
  ssh -A $1
}
# e.g.,
# function timwarnock { _sshconn 'timwarnock.com'; }


# tunnels
function _tunnel() {
	CMD="ssh -f `whoami`@$1 -L $2 -N"
	PID=`ps -e | grep "$CMD" | grep -v grep | awk '{ print $1 }'`
	if [ ! "$PID" == "" ]; then
		echo "killing old tunnel"
		kill -9 $PID
		sleep 1
	fi
	echo $CMD
	$CMD
}
# e.g.,
# function eg_tunnel { _tunnel proxyhost local-port:privatehost:port ; }


# load any local settings (specific to environment)
if [ -e ~/.bashrc_local ]; then
  . .bashrc_local
fi
