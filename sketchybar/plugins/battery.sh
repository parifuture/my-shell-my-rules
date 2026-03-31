#!/bin/bash

source "$CONFIG_DIR/colors.sh"

BATTERY_INFO="$(pmset -g batt)"
PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if ! echo "$BATTERY_INFO" | grep -q "InternalBattery"; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

[ "$PERCENTAGE" = "" ] && exit 0

COLOR=$WHITE
case "${PERCENTAGE}" in
[8-9][0-9] | 100) ICON=""; COLOR=$GREEN  ;;
[3-7][0-9])       ICON=""; COLOR=$YELLOW ;;
[1-2][0-9])       ICON=""; COLOR=$RED    ;;
*)                ICON=""               ;;
esac

[[ "$CHARGING" != "" ]] && ICON=""

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" icon.color=$COLOR
