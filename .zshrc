# OhMyZsh configuation
export ZSH="$(echo ~)/.oh-my-zsh"

# ZSH_THEME="blinks-time"
ZSH_THEME="blinks"
HIST_STAMPS="dd.mm.yyyy"
COMPLETION_WAITING_DOTS="true"

# add plugins to ~/.oh-my-zsh/custom/plugins/
plugins=(git)
source $ZSH/oh-my-zsh.sh

# initialize homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# make sure keys are added to the agent
if ! ssh-add -l | grep -q "luke.abel@simplethread.com"; then
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519
fi
if ! ssh-add -l | grep -q "luke.abel@gmail.com"; then
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519_pers
fi

# initialize fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# User configuration
setopt histignorealldups
unsetopt nomatch

## Autocomplete
autoload -Uz compinit
compinit
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate

## Paths 'n Flags
export USER_BIN=~/bin
export PATH=${USER_BIN}:$PATH
export PATH="/usr/local/sbin:$PATH"
export PATH="$(brew --prefix)/opt/libpq/bin:$PATH"
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export CPPFLAGS="-I$(brew --prefix)/opt/libpq/include"
export LDFLAGS="-L$(brew --prefix)/opt/libpq/lib"
export PKG_CONFIG_PATH="$(brew --prefix)/opt/libpq/lib/pkgconfig"

## Other Variables
export LANG=en_US.UTF-8
export RIPGREP_CONFIG_PATH=~/.ripgreprc
export NVM_DIR="$HOME/.nvm"

## Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
elif [[ -n $CODESPACES ]]; then
  export EDITOR='vim.tiny'
else
  export EDITOR='vim'
fi

## Aliases
# alias glog='git log --graph --oneline --decorate'
alias gpuo='git push -u origin $(current_branch)' # also gpsup
alias be='bundle exec'
alias rake='noglob rake' # required for certain strap tasks
alias linecount='tee >(wc -l | xargs echo)' # for piping ripgrep
alias caff='caffdown 36000'

function git-log-clean() {
  local log=$(git --no-pager log --pretty="%s. %b" --author=luke.abel@simplethread.com --since=$1 --until=$2 --all --no-merges)
  if [[ -n "$log" ]]; then
    echo "$log" | awk '!/^index on/' | awk '!x[$0]++' | sed 's/\*/\'$'\n\*/g' | sed '/^$/d' | sed '1!G;h;$!d'
  else
    echo "No commits found"
  fi
}
function git-echo-copy() {
  local yesterday=$(git-log-clean $1 $2)
  echo "$yesterday" 

  if [[ "$yesterday" != "No commits found" ]]; then
    git-log-clean $1 $2 | pbcopy
  fi
}

function gitToday() { git-echo-copy midnight }
function gitYesterday() { git-echo-copy yesterday.midnight midnight }

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

function rgcount() {
  rg $1 | tee >(wc -l | xargs echo)
}

# The following function runs the caffeinate command for a given number of seconds,
# and then displays a countdown for that amount of time.
# It hides the curser while the countdown is running, and then displays a message
# when the countdown is complete, and restores the cursor visibility.
function caffdown() {
  caffeinate -dimsut $1 &
  local caffeinate_pid=$!
  tput civis

  trap "local stop_script=1; kill $caffeinate_pid; tput cnorm; echo \"\n caffdown cancelled!\"" SIGINT SIGTERM EXIT

  for i in $(seq $1 -1 1); do
    local hours=$((i/3600))
    local minutes=$(( (i%3600)/60 ))
    local seconds=$(( (i%60) ))
    
    printf "%02d:%02d:%02d\033[0K\r" $hours $minutes $seconds

    if [[ $stop_script ]]; then
      break
    fi
    sleep 1
  done

  tput cnorm

  trap - SIGINT SIGTERM EXIT
}

# retrieve and set environment variables in the MacOS Keychain
function keychain-environment-variable () {
  security find-generic-password -w -a ${USER} -D "environment variable" -s "${1}"
}

function set-keychain-environment-variable () {
  [ -n "$1" ] || print "Missing environment variable name"
  read "?Enter Value for ${1}: " secret
  ( [ -n "$1" ] && [ -n "$secret" ] ) || return 1
  security add-generic-password -U -a ${USER} -D "environment variable" -s "${1}" -w "${secret}"
}

# Automatically set keychain-stored environment variables in the current shell
if command -v security >/dev/null 2>&1; then
  # export GITHUB_USER=$(keychain-environment-variable GITHUB_USER);
  # export GITHUB_TOKEN=$(keychain-environment-variable GITHUB_TOKEN);
fi

## Last Call
if [ "$(uname -s)" = "Darwin" ]; then
  eval "$(rbenv init -)"
  [ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
fi


