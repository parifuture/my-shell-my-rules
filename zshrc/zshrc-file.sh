# ~/code/personal/my-shell-my-rules/zshrc/zshrc-file.sh
# This file is symlinked to ~/.zshrc
# ln -snf ~/code/personal/my-shell-my-rules/zshrc/zshrc-file.sh ~/.zshrc

source ~/code/personal/my-shell-my-rules/zshrc/zshrc-common.sh

# Detect OS
case "$(uname -s)" in
Darwin)
  OS='Mac'
  ;;
Linux)
  OS='Linux'
  ;;
*)
  OS='Other'
  ;;
esac

if [ "$OS" = 'Mac' ]; then
  source ~/code/personal/my-shell-my-rules/zshrc/zshrc-macos.sh
elif [ "$OS" = 'Linux' ]; then
  source ~/code/personal/my-shell-my-rules/zshrc/zshrc-linux.sh
fi
