#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Get CPU usage percentage
CPU=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%' | cut -d. -f1)

if [ -z "$CPU" ]; then
  CPU="--"
  COLOR=$GREY
elif [ "$CPU" -ge 80 ]; then
  COLOR=$RED
elif [ "$CPU" -ge 50 ]; then
  COLOR=$YELLOW
else
  COLOR=$GREEN
fi

sketchybar --set "$NAME" label="${CPU}%" label.color=$COLOR
