#!/bin/bash

cpu=(
  label.font="$FONT:Heavy:12"
  label=CPU
  icon.drawing=off
  update_freq=4
  updates=on
  padding_right=15
  width=55
  script="$PLUGIN_DIR/cpu.sh"
)

sketchybar --add item cpu right \
  --set cpu "${cpu[@]}"
