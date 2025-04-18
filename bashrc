#
# this is a .bashrc file I use across multiple environments,
# environment specific settings (such as ssh tunnel configs) I put in .bashrc_local
#
export LANG=en_US.UTF-8
export HOSTNAME=$(hostname)

# turn off trap DEBUG (turned on at the end for screen window title)
trap "" DEBUG

## backspace
#if [ -t 0 ]; then
#  stty erase '^H'
#fi

# set vi shell
set -o vi

# path
export PATH=$PATH:.:/usr/local/bin:/usr/local/sbin:~/bin

# check if a command exists (similar to command -v)
command_exists() {
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
function mysqle() { mysql --defaults-group-suffix=$1 --password "${@:2}"; }

# mysql debug (localhost)
function msdebug() {
  cmd='sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings'
  echo $cmd
  sudo /usr/sbin/tcpdump -n port 3306 -s0 -w- | strings
}

# Python
export PYTHONSTARTUP=~/.pythonstartup
export PYTHONPATH=.:$PYTHONPATH

# set cursor
txtblk='\001\033[0;30m\002'   # Black - Regular
txtred='\001\033[0;31m\002'   # Red
txtgrn='\001\033[0;32m\002'   # Green
txtylw='\001\033[0;33m\002'   # Yellow
txtblu='\001\033[0;34m\002'   # Blue
txtpur='\001\033[0;35m\002'   # Purple
txtcyn='\001\033[0;36m\002'   # Cyan
txtwht='\001\033[0;37m\002'   # White
txtgry='\001\033[0;90m\002'   # Grey
bldblk='\001\033[1;30m\002'   # Black - Bold
bldred='\001\033[1;31m\002'   # Red
bldgrn='\001\033[1;32m\002'   # Green
bldylw='\001\033[1;33m\002'   # Yellow
bldblu='\001\033[1;34m\002'   # Blue
bldpur='\001\033[1;35m\002'   # Purple
bldcyn='\001\033[1;36m\002'   # Cyan
bldwht='\001\033[1;37m\002'   # White
txtrst='\001\033[0m\002'      # Text Reset
txtorg='\001\033[38;5;208m\002'   # Bitcoin Orange - Regular
bldorg='\001\033[1;38;5;208m\002'   # Bitcoin Orange - Bold
btc_symbol="₿"
smiley() { 
  if [ $? == 0 ]; then
    printf "$txtorg${btc_symbol}$txtrst"
  else 
    printf "$bldred!oops :($txtrst"
  fi
}

## git aliases
git config --global alias.hub \
        '!open "$(git ls-remote --get-url | sed "s|git@github.com:\(.*\)$|https://github.com/\1|" | sed "s|\.git$||")";'

which-git-branch() {
  PRE_RET=$?
  GIT_BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  printf "$GIT_BRANCH"
  return $PRE_RET
}
git-branch-fmt() {
  PRE_RET=$?
  #GIT_BRANCH=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  GIT_BRANCH=$(which-git-branch)
  if [ "$GIT_BRANCH" == "" ]; then
    printf "-"
  elif [[ $GIT_BRANCH = master* || $GIT_BRANCH = main* ]]; then
    printf "$bldblu[$txtblu$GIT_BRANCH$bldblu]$txtrst"
  else
    printf "$bldred[$txtred$GIT_BRANCH$bldred]$txtrst"
  fi   
  return $PRE_RET
}
which-venv() {
  PRE_RET=$?
  VENV_NAME=""
  if hash pyenv 2>/dev/null && test -f ".python-version"; then
    VENV_NAME="($(pyenv version-name)) "
  fi
  printf "$txtgry$VENV_NAME$txtrst"
  return $PRE_RET
}
#PS1="$bldblk\w \$(git-branch-fmt) \$(smiley)$txtrst "
#PS1="\$(which-venv)$bldblu\u$txtrst@$txtblu\h$txtwht:\w \$(git-branch-fmt) \$(smiley)$txtrst "
PS1="\$(which-venv)$bldblu\u$txtrst@$txtblu\$HOSTNAME$txtwht:\w \$(git-branch-fmt) \$(smiley)$txtrst "

# svn
export SVN_EDITOR=vim
alias svne='echo svn propedit svn:externals; svn propedit svn:externals'
alias svnu='echo svn up --ignore-externals; svn up --ignore-externals'

# ls aliases
ls -G >/dev/null 2>&1
if [ $? == 0 ]; then
  colorflag='-G'
else
  ls --color=tty >/dev/null 2>&1
  if [ $? == 0 ]; then
    colorflag='--color=tty'
  fi
fi
alias l="ls $colorflag"
alias ll="ls -lh $colorflag"
alias lll="ls -lah $colorflag"

# aliases
alias vi=vim
alias c=clear
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
alias tmuxa='tmux attach'


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


##
# git 
##
function git-default-branch {
  echo $(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
}
function git-master-or-main {
  DEFAULT_BRANCH=master
  git rev-parse --verify $DEFAULT_BRANCH >/dev/null 2>&1
  if [ $? != 0 ]; then
    DEFAULT_BRANCH=main
  fi
  echo $DEFAULT_BRANCH
}
function git-clean-branches {
  git checkout $(git-default-branch) && \
  git pull && \
  git branch --merged | egrep -v $(git-default-branch) | xargs git branch -D && \
  git remote prune origin
}
function git-pr-push {
  git push -u origin $(which-git-branch)
}
function git-all() {
    git add .
    git commit -a -m "$1"
    git push
}

##
# ssh agent -- for shared home directory across hosts
#
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
if [ "$TERM" = "screen" -o "$TERM" = "screen-256color" -o "$TERM" = "tmux-256color" ]; then
	export PROMPT_COMMAND='true'
	set_screen_window() {
	  HPWD=`basename "$PWD"`
	  if [ "$HPWD" = "$USER" ]; then HPWD='~'; fi
	  case "$BASH_COMMAND" in
		*\033]0*);;
		"true"|"bash")
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

clear
