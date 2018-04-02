# Path to your oh-my-zsh installation.
export ZSH=/Users/lhabel/.oh-my-zsh
ZSH_THEME="af-magic"
HIST_STAMPS="dd.mm.yyyy"

# add plugins to ~/.oh-my-zsh/custom/plugins/
plugins=(git)

source $ZSH/oh-my-zsh.sh

# Paths
export USER_SCRIPTS=~/bin
export PATH=${USER_SCRIPTS}:$PATH

# export MANPATH="/usr/local/man:$MANPATH"

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# aliases
alias cproglang='evince ~/books/the_c_programming_language_2.pdf &'
