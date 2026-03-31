#!/bin/bash

volume_slider=(
  script="$PLUGIN_DIR/volume.sh"
  updates=on
  label.drawing=off
  icon.drawing=off
  padding_right=3
  slider.highlight_color=$BLUE
  slider.background.height=5
  slider.background.corner_radius=3
  slider.background.color=$BACKGROUND_2
  slider.knob=􀀁
  slider.knob.drawing=on
)

volume_icon=(
  click_script="$PLUGIN_DIR/volume_click.sh"
  padding_left=10
  icon=$VOLUME_100
  icon.width=0
  icon.align=left
  icon.color=$WHITE
  icon.font="$FONT:Regular:14.0"
  label.width=25
  label.align=left
  label.font="$FONT:Regular:14.0"
)

# Detect initial audio output
CONNECTED_OUTPUT=$(SwitchAudioSource -t output -c 2>/dev/null)
if [[ "$CONNECTED_OUTPUT" == *"AirPods"* ]]; then
  volume_icon[2]="icon=$AIRPODS"
elif [[ "$CONNECTED_OUTPUT" == *"External"* ]]; then
  volume_icon[2]="icon=$HEADPHONES"
fi

status_bracket=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
)

sketchybar --add slider volume right \
  --set volume "${volume_slider[@]}" \
  --subscribe volume volume_change mouse.clicked \
  \
  --add item volume_icon right \
  --set volume_icon "${volume_icon[@]}"

sketchybar --add bracket status brew wifi volume_icon \
  --set status "${status_bracket[@]}"
