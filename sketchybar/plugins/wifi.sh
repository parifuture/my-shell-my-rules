#!/bin/bash

update() {
  source "$CONFIG_DIR/icons.sh"

  SSID="$(/System/Library/PrivateFrameworks/Apple80211.framework/Resources/airport -I | awk -F ' SSID: ' '/ SSID: / {print $2}')"
  INTERFACE="$(route get default | grep interface | awk '{print $2}')"
  HARDWARE_TYPE="$(networksetup -listnetworkserviceorder | grep -B 1 "Device: $INTERFACE" | head -n 1 | awk '{print $2}')"
  IP="$(ipconfig getifaddr "$INTERFACE")"

  if [[ "$HARDWARE_TYPE" == "Wi-Fi" ]]; then
    ICON="$([ -n "$IP" ] && echo "$WIFI_CONNECTED" || echo "$WIFI_DISCONNECTED")"
  else
    ICON="$([ -n "$IP" ] && echo "$ETHERNET_CONNECTED" || echo "$WIFI_DISCONNECTED")"
  fi

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
