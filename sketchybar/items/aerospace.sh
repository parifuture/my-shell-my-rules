#!/bin/bash
# Workspace indicators for AeroSpace
# Highlights the focused workspace, dims inactive ones

WORKSPACE_ICONS=("1" "2" "3" "4")

for i in "${!WORKSPACE_ICONS[@]}"; do
  sid=$((i + 1))

  workspace=(
    icon="${WORKSPACE_ICONS[i]}"
    icon.padding_left=8
    icon.padding_right=8
    padding_left=2
    padding_right=2
    icon.highlight_color=$GREEN
    icon.color=$GREY
    background.color=$BACKGROUND_1
    background.border_color=$BACKGROUND_2
    script="$PLUGIN_DIR/aerospace.sh"
    click_script="aerospace focus --workspace $sid"
  )

  sketchybar --add item workspace.$sid left \
    --set workspace.$sid "${workspace[@]}" \
    --subscribe workspace.$sid aerospace_workspace_change
done
