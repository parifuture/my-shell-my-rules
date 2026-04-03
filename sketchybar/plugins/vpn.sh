#!/bin/bash

source "$CONFIG_DIR/icons.sh"
source "$CONFIG_DIR/colors.sh"

update() {
  # Cisco Secure Client assigns a private IP to a utun interface when connected
  if ifconfig | grep -A 5 "^utun" | grep -q "inet [0-9].*-->"; then
    ICON="$VPN_CONNECTED"
    COLOR=$GREEN
  else
    ICON="$VPN_DISCONNECTED"
    COLOR=$GREY
  fi

  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR"
}

click() {
  open -a "Cisco Secure Client"
}

case "$SENDER" in
"routine")       update ;;
"forced")        update ;;
"mouse.clicked") click  ;;
esac
