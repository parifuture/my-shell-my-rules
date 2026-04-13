# ~/code/personal/my-shell-my-rules/zshrc/modules/symlinks.sh
# Creates all symlinks from ~/.config to this repo
# Runs on every shell start — idempotent, safe to re-run

DOTFILES="$HOME/code/personal/my-shell-my-rules"

# Ensure ~/.config exists
mkdir -p "$HOME/.config"

# NOTE: After first brew install, run once to register the new bash:
#   sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
# This does NOT change your default shell (we use zsh) — it just makes
# the modern bash available system-wide for scripts that invoke it.

# Helper: create symlink only if it doesn't already point to the right place
link() {
  local src="$1"
  local dest="$2"
  if [ ! -L "$dest" ] || [ "$(readlink "$dest")" != "$src" ]; then
    ln -snf "$src" "$dest"
  fi
}

# zshrc
link "$DOTFILES/zshrc/zshrc-file.sh" "$HOME/.zshrc"

# btop
link "$DOTFILES/btop" "$HOME/.config/btop"

# kitty
link "$DOTFILES/kitty" "$HOME/.config/kitty"

# atuin
mkdir -p "$HOME/.config/atuin"
link "$DOTFILES/atuin/config.toml" "$HOME/.config/atuin/config.toml"

# eligere
mkdir -p "$HOME/.config/eligere"
link "$DOTFILES/eligere/eligere.toml" "$HOME/.config/eligere/eligere.toml"

# fastfetch
link "$DOTFILES/fastfetch" "$HOME/.config/fastfetch"

# kanata
mkdir -p "$HOME/.config/kanata"
link "$DOTFILES/kanata/kanata.kbd" "$HOME/.config/kanata/kanata.kbd"

# lazygit
mkdir -p "$HOME/Library/Application Support/lazygit"
link "$DOTFILES/lazygit/config.yml" "$HOME/Library/Application Support/lazygit/config.yml"

# vscode
mkdir -p "$HOME/Library/Application Support/Code/User"
link "$DOTFILES/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"

# yazi
link "$DOTFILES/yazi" "$HOME/.config/yazi"

# neovim (kickstart as the default config)
link "$DOTFILES/neovim" "$HOME/.config/nvim"

# neovide
mkdir -p "$HOME/.config/neovide"
link "$DOTFILES/neovide/config.toml" "$HOME/.config/neovide/config.toml"

# claude code (only if installed)
if command -v claude &>/dev/null; then
  mkdir -p "$HOME/.claude/scripts"
  link "$DOTFILES/claude-code/scripts/context-bar.sh" "$HOME/.claude/scripts/context-bar.sh"
  link "$DOTFILES/claude-code/settings.json" "$HOME/.claude/settings.json"
fi

# litellm proxy (launchd daemon for Bedrock → OpenAI-compatible bridge)
if command -v litellm &>/dev/null; then
  mkdir -p "$HOME/.local/log"
  link "$DOTFILES/litellm/com.partiwari.litellm-proxy.plist" "$HOME/Library/LaunchAgents/com.partiwari.litellm-proxy.plist"
fi
