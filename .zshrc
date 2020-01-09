# OhMyZsh configuation

# Path to your oh-my-zsh installation.
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

# Import colorscheme from 'wal' asynchronously
# &   # Run the process in the background.
# ( ) # Hide shell job control messages.
# (cat ~/.cache/wal/sequences &)

# Paths
export USER_BIN=~/bin
export PATH=${USER_BIN}:$PATH
export PATH="/usr/local/opt/libxml2/bin:$PATH"
export PATH="/usr/local/sbin:$PATH"
export PKG_CONFIG_PATH="/usr/local/opt/libffi/lib/pkgconfig"
export LDFLAGS="-L/usr/local/opt/zlib/lib"


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# Aliases
alias glog='git log --graph --oneline --decorate'
alias be='bundle exec'
alias rake="noglob rake" # required for certain strap tasks
alias inklinks='mdcat ~/repos/gists/inklinks/inklinks.md'
alias inknotes='mdcat ~/repos/gists/inknotes/inknotes.md'
alias railsnotes='mdcat ~/repos/gists/railsnotes/railsnotes.md'
function list_servers () {
  cd ~/repos/autotomy
  bundle exec cap apps:$1:$2 list:servers
  cd -
}

eval "$(rbenv init -)"
eval "$(pyenv init -)"
eval "$(nodenv init -)"
