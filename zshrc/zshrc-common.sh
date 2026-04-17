# ~/code/my-shell-my-rules/zshrc/zshrc-common.sh
# Loaded first by zshrc-file.sh — platform-agnostic config
# $DOTFILES is exported by zshrc-file.sh before this file is sourced

source "$DOTFILES/zshrc/modules/symlinks.sh"
source "$DOTFILES/zshrc/modules/autocompletion.sh"
source "$DOTFILES/zshrc/modules/history.sh"
source "$DOTFILES/zshrc/modules/alias-common.sh"

# services.sh uses launchctl — macOS only
if [[ "$(uname -s)" == "Darwin" ]]; then
  source "$DOTFILES/zshrc/modules/services.sh"
fi

source "$DOTFILES/zshrc/modules/secrets.sh"
