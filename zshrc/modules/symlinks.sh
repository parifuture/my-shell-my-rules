# ~/code/my-shell-my-rules/zshrc/modules/symlinks.sh
# Creates all symlinks from ~/.config to this repo
# Runs on every shell start — idempotent, safe to re-run
# $DOTFILES is exported by zshrc-file.sh before this file is sourced

# NOTE: After first brew install, run once to register the new bash:
#   sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
# This does NOT change your default shell (we use zsh) — it just makes
# the modern bash available system-wide for scripts that invoke it.

mkdir -p "$HOME/.config"

OS="$(uname -s)"

# Helper: create symlink only if it doesn't already point to the right place
link() {
  local src="$1"
  local dest="$2"
  if [ ! -L "$dest" ] || [ "$(readlink "$dest")" != "$src" ]; then
    ln -snf "$src" "$dest"
  fi
}

#############################################################################
#                     Cross-platform (macOS + Linux/WSL2)
#############################################################################

# zshrc
link "$DOTFILES/zshrc/zshrc-file.sh" "$HOME/.zshrc"

# btop
link "$DOTFILES/btop" "$HOME/.config/btop"

# atuin
mkdir -p "$HOME/.config/atuin"
link "$DOTFILES/atuin/config.toml" "$HOME/.config/atuin/config.toml"

# fastfetch
link "$DOTFILES/fastfetch" "$HOME/.config/fastfetch"

# yazi
link "$DOTFILES/yazi" "$HOME/.config/yazi"

# neovim (kickstart as the default config)
link "$DOTFILES/neovim" "$HOME/.config/nvim"

# claude code (only if installed)
if command -v claude &>/dev/null; then
  mkdir -p "$HOME/.claude/scripts"
  link "$DOTFILES/claude-code/scripts/context-bar.sh" "$HOME/.claude/scripts/context-bar.sh"
  link "$DOTFILES/claude-code/settings.json" "$HOME/.claude/settings.json"
fi

# lazygit — config path differs per OS
if [[ "$OS" == "Darwin" ]]; then
  mkdir -p "$HOME/Library/Application Support/lazygit"
  link "$DOTFILES/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"
else
  mkdir -p "$HOME/.config/lazygit"
  link "$DOTFILES/lazygit/config.yml" "$HOME/.config/lazygit/config.yml"
fi

# vscode — config path differs per OS
if [[ "$OS" == "Darwin" ]]; then
  mkdir -p "$HOME/Library/Application Support/Code/User"
  link "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
else
  mkdir -p "$HOME/.config/Code/User"
  link "$DOTFILES/vscode/settings.json" "$HOME/.config/Code/User/settings.json"
fi

#############################################################################
#                          macOS only
#############################################################################

if [[ "$OS" == "Darwin" ]]; then
  # kitty
  link "$DOTFILES/kitty" "$HOME/.config/kitty"

  # eligere (browser picker)
  mkdir -p "$HOME/.config/eligere"
  link "$DOTFILES/eligere/eligere.toml" "$HOME/.config/eligere/eligere.toml"

  # aerospace (tiling window manager)
  mkdir -p "$HOME/.config/aerospace"
  link "$DOTFILES/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"

  # kanata (keyboard remapper)
  mkdir -p "$HOME/.config/kanata"
  link "$DOTFILES/kanata/kanata.kbd" "$HOME/.config/kanata/kanata.kbd"

  # sketchybar (menu bar)
  link "$DOTFILES/sketchybar" "$HOME/.config/sketchybar"

  # neovide (GUI neovim wrapper)
  mkdir -p "$HOME/.config/neovide"
  link "$DOTFILES/neovide/config.toml" "$HOME/.config/neovide/config.toml"

  # litellm proxy (launchd daemon for Bedrock bridge)
  if command -v litellm &>/dev/null; then
    mkdir -p "$HOME/.local/log"
    link "$DOTFILES/litellm/com.partiwari.litellm-proxy.plist" "$HOME/Library/LaunchAgents/com.partiwari.litellm-proxy.plist"
  fi
fi

#############################################################################
#                          Linux / WSL2 only
#############################################################################

if [[ "$OS" == "Linux" ]]; then
  # WezTerm — config must live on the Windows filesystem for WezTerm to read it.
  # The symlink here is for reference only; the active config is deployed via:
  #   cp $DOTFILES/wezterm/wezterm.lua /mnt/c/Users/<you>/.config/wezterm/wezterm.lua
  # WezTerm auto-reloads on file change.
  :
fi
