#!/bin/bash

source "$CONFIG_DIR/colors.sh"

DND_ENABLED=$(plutil -convert json -o - ~/Library/DoNotDisturb/DB/Assertions.json 2>/dev/null | jq -r '.data[0].storeAssertionRecords')

if [ "$DND_ENABLED" = "null" ] || [ -z "$DND_ENABLED" ]; then
  sketchybar -m --set dnd label="" icon.drawing=off
else
  sketchybar -m --set dnd label="DND" icon=􀆺 icon.color=$ORANGE label.color=$ORANGE icon.drawing=on
fi
