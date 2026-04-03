#!/bin/bash

source "$CONFIG_DIR/icons.sh"

vpn=(
  padding_right=0
  padding_left=6
  label.width=0
  icon="$VPN_DISCONNECTED"
  icon.color=$GREY
  update_freq=10
  script="$PLUGIN_DIR/vpn.sh"
)

sketchybar --add item vpn right \
  --set vpn "${vpn[@]}" \
  --subscribe vpn mouse.clicked
