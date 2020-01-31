# OhMyZsh configuation
export ZSH="/Users/lukeabel/.oh-my-zsh"
export DOCKER_BUILDKIT=1

# ZSH_THEME="clean" # has timestamp
# ZSH_THEME="blinks" # has topbar
ZSH_THEME="blinks-time"
HIST_STAMPS="dd.mm.yyyy"
# HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true" # speeds up large repos

# add plugins to ~/.oh-my-zsh/custom/plugins/
plugins=(git)
source $ZSH/oh-my-zsh.sh

# User configuration

## Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

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
export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"
export LDFLAGS="-L/usr/local/opt/zlib/lib"

## Aliases
# alias glog='git log --graph --oneline --decorate'
alias be='bundle exec'
alias rake="noglob rake" # required for certain strap tasks
alias inklinks='mdcat ~/repos/gists/inklinks/inklinks.md'
alias inknotes='mdcat ~/repos/gists/inknotes/inknotes.md'
alias railsnotes='mdcat ~/repos/gists/railsnotes/railsnotes.md'

## Functions
function servers () {
  cd ~/repos/autotomy && git pull
  bundle exec cap apps:$1:$2 list:servers
  cd -
}
function deploy () {
  cd ~/repos/autotomy && git pull
  bundle exec cap apps:$1:$2 deploy
  cd -
}

function tail_log () {
  cd ~/repos/autotomy && git pull
  bundle exec cap apps:$1:$2 tail:app_log
  cd -
}

function stageon {
  PROJECT=$(basename $PWD)
  # groups is www-groups in autotomy
  if [ "$PROJECT" == "groups" ]; then
    PROJECT="www-$PROJECT"
  fi
  BRANCH=$(git rev-parse --abbrev-ref HEAD)
  HOSTS=$1.staging.customink.com BRANCH=$BRANCH deploy $PROJECT staging
}

## Last Call
eval "$(rbenv init -)"
eval "$(pyenv init -)"
eval "$(nodenv init -)"
