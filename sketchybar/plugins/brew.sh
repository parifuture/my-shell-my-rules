#!/bin/bash

source "$CONFIG_DIR/colors.sh"

export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_DOWNLOAD_CONCURRENCY=1

if OUT="$(brew outdated 2>/dev/null)"; then
  if [ -z "$OUT" ]; then
    COUNT=0
  else
    COUNT="$(printf "%s\n" "$OUT" | wc -l | tr -d ' ')"
  fi
else
  COUNT="!"
  COLOR=$RED
fi

case "$COUNT" in
[3-5][0-9]) COLOR=$ORANGE ;;
[1-2][0-9]) COLOR=$YELLOW ;;
[1-9])      COLOR=$WHITE  ;;
0)
  COLOR=$GREEN
  COUNT=􀆅
  ;;
esac

sketchybar --set "$NAME" label=$COUNT icon.color=$COLOR
