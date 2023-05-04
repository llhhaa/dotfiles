# OhMyZsh configuation

export ZSH="$(echo ~)/.oh-my-zsh"

# ZSH_THEME="blinks-time"
ZSH_THEME="blinks"
HIST_STAMPS="dd.mm.yyyy"
COMPLETION_WAITING_DOTS="true"

# add plugins to ~/.oh-my-zsh/custom/plugins/
plugins=(git)
source $ZSH/oh-my-zsh.sh

# User configuration
setopt INC_APPEND_HISTORY # important for devkick
unsetopt nomatch

## Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

## Autocomplete
autoload -Uz compinit
compinit
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate

## Paths
export USER_BIN=~/bin

export PATH=${USER_BIN}:$PATH
export PATH="/usr/local/opt/libxml2/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PATH="/usr/local/opt/libiconv/bin:$PATH"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="$PATH:$HOME/repos/devkick-control/cli"

# Generated by Strap - PATH
export PATH=/usr/local/opt/mysql-client@5.7/bin:$PATH

export CPPFLAGS="-I/usr/local/opt/libiconv/include"

export LDFLAGS="-L/usr/local/opt/zlib/lib:$LDFLAGS"
export LDFLAGS="-L/usr/local/opt/libiconv/lib:$LDFLAGS"

if [ "$(uname -s)" = "Darwin" ]; then
  export LDFLAGS="$LDFLAGS:-L$(brew --prefix)/opt/libffi/lib"
  export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(brew --prefix)/opt/libffi/lib/pkgconfig"
fi

### AWS stuff
export AWS_SESSION_SOURCE_PROFILE=default
export AWS_SESSION_MFA=
export AWS_SESSION_ROLE=
export AWS_SESSION_CI_STANDARD_PROFILES=true

export AUTOTOMY_ROOT=~/repos/autotomy
export RIPGREP_CONFIG_PATH=~/.ripgreprc

# This will set the LANG variable for your environment
export LANG=en_US.UTF-8

# Generated by Strap - PUMADEV_SOURCE_ENV
export PUMADEV_SOURCE_ENV=0

export DOCKER_BUILDKIT=1

## Aliases
# alias glog='git log --graph --oneline --decorate'
alias gpuo='git push -u origin $(current_branch)'
alias be='bundle exec'
alias rake='noglob rake' # required for certain strap tasks
alias inklinks='mdcat ~/repos/gists/inklinks/inklinks.md'
alias inknotes='mdcat ~/repos/gists/inknotes/inknotes.md'
alias railsnotes='mdcat ~/repos/gists/railsnotes/railsnotes.md'
alias linecount='tee >(wc -l | xargs echo)' # for piping ripgrep
alias login_aws='~/repos/aws_login/build/darwin-amd64/aws_login' # until it's in homebrew
alias caff='caffeinate -dimsut 36000'
alias cafftime='pmset -g assertions'

## Functions
function rtest () {
  if ! [[ -z "$2" ]]; then
    ruby -I test $1 -n "/$2/"
  else
    ruby -I test $1
  fi
}

function runtest () {
  if ! [[ -z "$2" ]]; then
    bin/run ruby -I test $1 -n "/$2/"
  else
    bin/run ruby -I test $1
  fi
}

function servers () {
  cd $AUTOTOMY_ROOT && git pull
  bundle exec cap apps:$1:$2 list:servers
  cd -
}

function deploy () {
  cd $AUTOTOMY_ROOT && git pull
  bundle exec cap apps:$1:$2 deploy
  cd -
}

function tail_log () {
  cd $AUTOTOMY_ROOT && git pull
  bundle exec cap apps:$1:$2 tail:app_log
  cd -
}

# get running pods whose name includes a substring
# param1: namespace
# param2: pod name substring
function kpods () {
  kubectl get pods -n $1 | rg -oP "$2\S*(?=\s+\d+\/\d+\s+Running)"
}

# log into a pod of the given name
# param1: namespace
# param2: pod name
function kshell () {
  ContainerType=$(echo "$2" | rg -oP ".*(?=(-[^a-z][a-z0-9]*){2})")
  kubectl -n $1 -c "$ContainerType" exec -it "$2" -- /bin/bash
}

# log into the first running pod whose name includes a substring
# param1: namespace
# param2: pod name substring
function kshellfirst () {
  ContainerName=$(kpods $1 $2 | head -n1)
  ContainerType=$(echo "$ContainerName" | rg -oP ".*(?=(-[^a-z][a-z0-9]*){2})")
  kubectl -n $1 -c "$ContainerType" exec -it "$ContainerName" -- /bin/bash
}

# find filenames that look like arg
function rgg() {
  rg --iglob "*$1*" -g '!/Library/' --files
}

# match literal string for arg
function rgl() {
  rg -F $1 $2
}

# match a string in files AND filenames
function rga() {
  ( rg $1; rgg $1 )
}

# find and replace. leave second arg blank for find-and-remove.
# supports filenames with whitespace.
function rgr() {
  rg $1 --files-with-matches -0 | xargs -0 sed -i '' "s/$1/$2/g"
}

function shorten() {
  if ! [[ -z "$2" ]]; then
    curl -i https://git.io -F "url=$1" -F "code=$2"
  else
    curl -i https://git.io -F "url=$1"
  fi
}

## Last Call
if [ "$(uname -s)" = "Darwin" ]; then
  eval "$(rbenv init -)"
else
  if [ -e .ruby-version ]; then
    cd ..; cd - > /dev/null
  fi
fi

if [ -e ~/.github-credentials ]; then
  . ~/.github-credentials
fi

if [ "$(uname -s)" = "Darwin" ]; then
  eval "$(pyenv init -)"
fi

eval "$(nodenv init -)"
