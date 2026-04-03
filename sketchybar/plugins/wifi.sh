#!/bin/bash

update() {
  source "$CONFIG_DIR/icons.sh"

  # Check Wi-Fi status directly — don't rely on default route (VPN changes it)
  WIFI_INTERFACE="en0"
  SSID="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F ' SSID: ' '/ SSID: / {print $2}')"
  IP="$(ipconfig getifaddr "$WIFI_INTERFACE")"

  ICON="$([ -n "$IP" ] && echo "$WIFI_CONNECTED" || echo "$WIFI_DISCONNECTED")"
  LABEL="$([ -n "$IP" ] && echo "$SSID ($IP)" || echo "Disconnected")"
  sketchybar --set "$NAME" icon="$ICON" label="$LABEL"
}

click() {
  CURRENT_WIDTH="$(sketchybar --query "$NAME" | jq -r .label.width)"
  WIDTH=0
  [ "$CURRENT_WIDTH" -eq "0" ] && WIDTH=dynamic
  sketchybar --animate sin 20 --set "$NAME" label.width="$WIDTH"
}

case "$SENDER" in
"wifi_change")   update ;;
"mouse.clicked") click  ;;
esac
