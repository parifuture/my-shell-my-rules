#!/bin/bash

source "$CONFIG_DIR/colors.sh"

export HOMEBREW_DOWNLOAD_CONCURRENCY=1

if OUT="$(brew outdated 2>&1)"; then
  COUNT="$(printf "%s\n" "$OUT" | wc -l | tr -d ' ')"
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
