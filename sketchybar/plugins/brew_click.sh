#!/bin/bash

export PATH="/opt/homebrew/bin:$PATH"
export HOMEBREW_DOWNLOAD_CONCURRENCY=4

# Show updating indicator immediately
sketchybar --set "$NAME" label="⏳" icon.color=0xfff1fc79

# Run update+upgrade in background, then refresh the count
(
  brew update 2>/dev/null
  brew upgrade 2>/dev/null
  # Trigger the main brew plugin to refresh the count
  CONFIG_DIR="$CONFIG_DIR" NAME="$NAME" source "$CONFIG_DIR/plugins/brew.sh"
) &
