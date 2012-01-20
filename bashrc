
## backspace
stty erase '^H'

# set vi shell
set -o vi

# path
export PATH=.:/usr/local/bin:~/bin:$PATH

# functions
function msdebug() {
  cmd='sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings'
  echo $cmd
  sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings
}

# Oracle
export TNS_ADMIN=$HOME/bin
export ORACLE_HOME=/usr/lib/oracle/10.2.0.4/client64
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib:/usr/local/lib
export PATH=$PATH:$ORACLE_HOME/bin
export SQLPATH=.:~/bin

# Python
export PYTHONSTARTUP=~/.pythonstartup

# set smiley cursor
smiley () { if [ $? == 0 ]; then echo ':)'; else echo ':('; fi; }
export PS1="\[\033[01;31m\]\u@\h\[\033[01;34m\]:\w \$(smiley)\[\033[00m\] "
# export PS1="\[\033[01;31m\]\u@\h\[\033[01;34m\]:\w\n\$(smiley)\[\033[00m\] "

# mysql prompt
export MYSQL_PS1='\d> '

# svn
export SVN_EDITOR=vim

# cvs
export CVSROOT=:ext:twarnock@cvs.prvt.nytimes.com:/nytd/nytimes/src/cvs
export CVS_RSH=ssh

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
alias pd='pushd'
alias pd0='pushd +0 >/dev/null ; dirs -v'
alias pd1='pushd +1 >/dev/null ; dirs -v'
alias pd2='pushd +2 >/dev/null ; dirs -v'
alias pd3='pushd +3 >/dev/null ; dirs -v'
alias pd4='pushd +4 >/dev/null ; dirs -v'
alias d='dirs -v'
# alias ip="/sbin/ifconfig | grep 'inet addr:' | grep -v 127.0.0.1 | awk -F: '{ print \$2 }' | awk '{ print \$1 }'"
alias ip="/sbin/ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{ print \$2 }'"
# alias grep='grep --color=auto'
alias tags='ctags -R -f ~/.tags -h .h.H.hh.hpp.hxx.h++.inc.def --langmap=php:.php.php3.php4.phtml.inc'
alias svne='svn propedit svn:externals'


# ssh agent -- for shared home directory across hosts
SSH_ENV=$HOME/.ssh/.environment.`hostname`
function start_agent {
  echo "Starting a new ssh-agent on this host"
  ssh-agent | sed 's/^echo/#echo/' > ${SSH_ENV}
  chmod 600 ${SSH_ENV}
  . ${SSH_ENV} > /dev/null
  ssh-add;
  echo succeeded
}

## ssh-agent
if [ -e "$SSH_AUTH_SOCK" ]; then
  echo "Using ${SSH_AUTH_SOCK}"
elif [ -f "${SSH_ENV}" ]; then
  echo "Using ${SSH_ENV}"
  . ${SSH_ENV} > /dev/null
  ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
    echo "${SSH_ENV} agent is no longer running"
    start_agent;
  }
else
  start_agent;
fi

# hosts
function _sshconn() {
  echo "ssh -A $1"
  ssh -A $1
}
function laptop { _sshconn 'timothy-warnock-7303.nyhq.nytint.com'; }
function profileapi01 { _sshconn profileapi01.qprvt.nytimes.com; }
function profileapi02 { _sshconn profileapi02.qprvt.nytimes.com; }
function profileapi03 { _sshconn profileapi03.qprvt.nytimes.com; }
function profileapi04 { _sshconn profileapi04.qprvt.nytimes.com; }
function sartre-reporting { _sshconn sartre-reporting03.qprvt.nytimes.com; }
function userprefs-proc01 { _sshconn userprefs-proc01.qprvt.nytimes.com; }
function app1 { _sshconn app1.prvt.nytimes.com; }

