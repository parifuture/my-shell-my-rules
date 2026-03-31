# ~/code/my-shell-my-rules/zshrc/modules/history.sh

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=20000

if [[ ! -f $HISTFILE ]]; then
  touch $HISTFILE
  chmod 600 $HISTFILE
fi

setopt appendhistory     # append to history file, don't overwrite
setopt extendedhistory   # record timestamp of each command
setopt sharehistory      # share history across all sessions
setopt incappendhistory  # write to history file immediately, not on exit
setopt histignoredups    # ignore duplicate commands in a row
setopt histignorespace   # ignore commands that start with a space
