#!/bin/bash

brew=(
  icon=􀐛
  label=?
  update_freq=1800
  padding_right=12
  label.padding_left=2
  script="$PLUGIN_DIR/brew.sh"
)

sketchybar --add event brew_update \
  --add item brew right \
  --set brew "${brew[@]}" \
  --subscribe brew brew_update
