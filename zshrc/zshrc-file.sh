# ~/code/my-shell-my-rules/zshrc/zshrc-file.sh
# This file is symlinked to ~/.zshrc
# ln -snf ~/code/<path>/my-shell-my-rules/zshrc/zshrc-file.sh ~/.zshrc

# Auto-detect repo root by resolving the ~/.zshrc symlink back to the real file.
# %x = current source file path, :A = resolve symlinks, :h = parent directory
DOTFILES="${${(%):-%x}:A:h:h}"
export DOTFILES

source "$DOTFILES/zshrc/zshrc-common.sh"

case "$(uname -s)" in
Darwin) source "$DOTFILES/zshrc/zshrc-macos.sh" ;;
Linux)  source "$DOTFILES/zshrc/zshrc-linux.sh" ;;
esac

# OpenClaw Completion
source "/home/parikshit/.openclaw/completions/openclaw.zsh"
