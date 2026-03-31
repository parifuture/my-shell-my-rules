#!/bin/bash
# Highlights the focused AeroSpace workspace, dims all others

source "$CONFIG_DIR/colors.sh"

# Extract workspace number from item name (e.g. workspace.1 → 1)
CURRENT_WORKSPACE="${NAME##*.}"

if [ "$FOCUSED_WORKSPACE" = "$CURRENT_WORKSPACE" ]; then
  sketchybar --set "$NAME" icon.color=$GREEN background.color=$BG1
else
  sketchybar --set "$NAME" icon.color=$GREY background.color=$TRANSPARENT
fi
