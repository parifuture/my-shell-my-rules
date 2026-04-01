#!/bin/bash

export PATH="/opt/homebrew/bin:$PATH"

# Show updating indicator
sketchybar --set "$NAME" label="⏳" icon.color=0xfff1fc79

brew update 2>/dev/null
brew upgrade 2>/dev/null

# Re-run the main brew plugin to refresh the count
source "$CONFIG_DIR/plugins/brew.sh"
