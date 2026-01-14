#!/bin/bash

# Symlink dotfiles to their appropriate locations
# Run from anywhere - script determines its own location

set -e

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[SKIP]${NC} $1"; }
log_backup() { echo -e "${YELLOW}[BACKUP]${NC} $1"; }

# Create symlink, backing up existing files if necessary
link_file() {
  local src="$1"
  local dest="$2"

  # Create parent directory if needed
  mkdir -p "$(dirname "$dest")"

  # Check if destination already exists
  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink "$dest")"
    if [ "$current_target" = "$src" ]; then
      log_warn "$dest already linked correctly"
      return
    fi
    # Remove old symlink
    rm "$dest"
  elif [ -e "$dest" ]; then
    # Back up existing file/directory
    local backup="${dest}.bak"
    mv "$dest" "$backup"
    log_backup "Moved $dest to $backup"
  fi

  ln -s "$src" "$dest"
  log_info "Linked $dest -> $src"
}

echo "Installing dotfiles from $DOTFILES_DIR"
echo ""

# Shell
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Tmux
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Vim
link_file "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"

# Ripgrep
link_file "$DOTFILES_DIR/.rgignore" "$HOME/.rgignore"
link_file "$DOTFILES_DIR/.ripgreprc" "$HOME/.ripgreprc"

# Neovim (includes init.lua and lua/ configs)
link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
echo "         (includes nvim/init.lua, nvim/lua/plugins_manifest.lua, nvim/lua/gen_prompts.lua)"

# Kitty
link_file "$DOTFILES_DIR/kitty.conf" "$HOME/.config/kitty/kitty.conf"

# Claude Code (includes settings.json and scripts/)
link_file "$DOTFILES_DIR/.claude" "$HOME/.claude"

# Optional: Alacritty (uncomment if using)
# link_file "$DOTFILES_DIR/.alacritty.yml" "$HOME/.alacritty.yml"

echo ""
echo "Done!"
