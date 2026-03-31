#!/bin/bash

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" label="" label.drawing=off icon.background.image="app.$INFO"
fi
