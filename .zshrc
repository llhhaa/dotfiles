# OhMyZsh configuation
export ZSH="$(echo ~)/.oh-my-zsh"

# ZSH_THEME="blinks-time"
ZSH_THEME="blinks"
HIST_STAMPS="dd.mm.yyyy"
COMPLETION_WAITING_DOTS="true"

# add plugins to ~/.oh-my-zsh/custom/plugins/
plugins=(git z)
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

# Force use of OpenSSL 3.5
export PATH="/opt/homebrew/opt/openssl@3.5/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@3/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@3/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@3/lib/pkgconfig"
# For Ruby specifically
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@3"

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
  export EDITOR='nvim'
fi

## Aliases
# alias glog='git log --graph --oneline --decorate'
alias gpuo='git push -u origin $(current_branch)' # also gpsup
alias be='bundle exec'
alias rake='noglob rake' # required for certain strap tasks
alias linecount='tee >(wc -l | xargs echo)' # for piping ripgrep
alias caff='caffdown 36000'
alias baudit='bundle exec bundle-audit update && bundle exec bundle-audit check'
alias vim='nvim'

function n() {
  nvim $1
}

function gcam() {
  git commit -am $1
}

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

function timestamp () {
  timestamp=$(date +'%Y%m%d%H%M%S')
  echo $timestamp
  echo $timestamp | pbcopy
}

## Functions
# find filenames that look like arg
function rgg() {
  rg --iglob "*$1*" -g '!/Library/' --files
}

# match literal string for arg
# useful for characters that bash wants to interpret
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

# count occurrences of arg
function rgcount() {
  rg $1 | tee >(wc -l | xargs echo)
}

# search for an element by attribute key and/or value
function rgelement() {
  rg --multiline --multiline-dotall "<$1[^<]*$2[^<]*>"
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

function profanno() {
  local filepath="$1"
  local filename=$(basename "$filepath")

  be stackprof tmp/stackprof.dump --file "$filepath" > "tmp/$filename"
}

# Function to check out latest release canddiate branch
function gcol() {
  # fetch to make sure we have the latest branches
  git fetch

  # Get all branches matching the release candidate pattern
  branches=$(git branch -a | grep 'remotes/origin/v[0-9]*\.[0-9]*\(\.[0-9]*\)\?-candidate' | sed 's/.*remotes\/origin\///')

  # Initialize variables to store the latest version and branch
  latest_version="0.0.0"
  latest_branch=""

  # Iterate through the branches
  while IFS= read -r branch; do
    # Extract the version number from the branch name
    version=$(echo "$branch" | sed -E 's/.*v([0-9]+\.[0-9]+(\.[0-9]+)?)-candidate/\1/')

    # Compare the version with the current latest version
    if [[ "$version" > "$latest_version" ]]; then
      latest_version="$version"
      latest_branch="$branch"
    fi
  done <<< "$branches"

  # Check out the latest release candidate branch
  if [[ -n "$latest_branch" ]]; then
    git checkout "$latest_branch"

    # Check for updates and pull if needed
    git fetch origin "$latest_branch"
    if [[ $(git rev-parse HEAD) != $(git rev-parse origin/"$latest_branch") ]]; then
      echo "Updates found. Pulling latest changes..."
      git pull origin "$latest_branch"
    fi
  else
    echo "No release candidate branches found."
  fi
}

# Display Neovim configuration cheatsheet
function nvim-cheat() {
  cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                VIM CHEATSHEET                                 ║
╚═══════════════════════════════════════════════════════════════════════════════╝

─── FILE NAVIGATION (FZF) ──────────────────────────────────────────────────────
  <Space>f    Git files (:GFiles)
  <Space>F    All files (:Files)
  <Space>b    Buffers
  <Space>h    File history

─── CLIPBOARD ──────────────────────────────────────────────────────────────────
  <Space>y    Yank to system clipboard
  <Space>p/P  Paste/paste before from clipboard
  <Space>v    Replace word with reg 0
  <Space>yf   Yank filename

─── SEARCH / GREP ──────────────────────────────────────────────────────────────
  <Space>g    Grep word under cursor
  <Space>G    Grep in new tab
  <Space>l    Literal grep
  <Space>gl   Grep visual selection (visual)

─── GIT / GITHUB ───────────────────────────────────────────────────────────────
  <Space>B    Open file on GitHub (:GBrowse!)

─── WINDOW / SPLITS ────────────────────────────────────────────────────────────
  <Space>w    Window commands (<C-w>)
  <Space>S    Alternate file in split

─── TEXT OBJECTS ───────────────────────────────────────────────────────────────
  vie / vae / yie   Entire file
  vic / vac         Word column

─── INSERT MODE ────────────────────────────────────────────────────────────────
  def@      → def\nend
  info@       → Rails.logger.info()

─── PLUGINS ────────────────────────────────────────────────────────────────────
  vim-fugitive      Git integration         vim-rhubarb       GitHub :GBrowse
  fzf.vim           Fuzzy finder            vim-marked        Markdown preview
  vim-rails         Rails support           vim-bundler       :Bundle open
  vim-textobj-*     Text objects            claude-code.nvim  Claude AI
  gen.nvim          LLM (Ollama)

─── SETTINGS ───────────────────────────────────────────────────────────────────
  Line numbers: ON    Indent: 2 spaces    Color column: 80
  Search: smart-case  Scrolloff: 2 lines  Colorscheme: apprentice
EOF
}

# Function to create and open a timestamped scratch file
function makescratch() {
  # Check if a name was provided
  if [[ -z "$1" ]]; then
    echo "Error: Please provide a name for the scratch file."
    echo "Usage: makescratch <name>"
    return 1
  fi

  # Get the current timestamp in YYYYMMDD_HHMMSS format
  local timestamp=$(date +"%Y%m%d_%H%M%S")

  # Find the project root (assuming it's a git repository)
  local project_root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -z "$project_root" ]]; then
    echo "Error: Not in a git repository."
    return 1
  fi

  # Create the scratch directory if it doesn't exist
  local scratch_dir="${project_root}/scratch"
  mkdir -p "$scratch_dir"

  # Create the scratch file with the given name and timestamp
  local filename="${1}_${timestamp}.rb"
  local filepath="${scratch_dir}/${filename}"

  # Add a header comment to the file
  echo "# Scratch file: ${filename}" > "$filepath"
  echo "# Created: $(date)" >> "$filepath"
  echo "" >> "$filepath"

  # Open the file in Neovim
  nvim "$filepath"
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


export PATH="$PATH:/Users/lukeabel/Repos/devops_utilities"
alias devops='RBENV_VERSION=3.3.10 devops'
export PATH="$HOME/.local/bin:$PATH"
