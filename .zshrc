# OhMyZsh configuation

# Path to your oh-my-zsh installation.
export ZSH="/Users/lukeabel/.oh-my-zsh"

ZSH_THEME="af-magic"
HIST_STAMPS="dd.mm.yyyy"
# HYPHEN_INSENSITIVE="true"
COMPLETION_WAITING_DOTS="true"
# DISABLE_UNTRACKED_FILES_DIRTY="true" # speeds up large repos

# add plugins to ~/.oh-my-zsh/custom/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# Paths
export USER_SCRIPTS=~/scripts
export PATH=${USER_SCRIPTS}:$PATH

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

eval "$(rbenv init -)"
eval "$(nodenv init -)"
