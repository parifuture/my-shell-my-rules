#!/bin/bash
# Moves windows on the current workspace to their correct workspace
# based on app/title rules. Only affects the focused workspace.

# Define app-to-workspace rules (must match aerospace.toml)
get_target_workspace() {
  local app="$1"
  local title="$2"

  case "$app" in
    *Slack*|*Outlook*)
      echo 1 ;;
    *"Cisco Secure Client"*)
      echo 2 ;;
    *"Google Chrome"*)
      echo 3 ;;
    *Safari*)
      if [[ "$title" == *"EA Window"* ]]; then
        echo 1
      elif [[ "$title" == *"Personal"* ]]; then
        echo 4
      fi ;;
    *kitty*)
      echo 3 ;;
    *"Visual Studio Code"*|*Figma*)
      echo 3 ;;
    *Obsidian*)
      echo 4 ;;
  esac
}

CURRENT_WS=$(aerospace list-workspaces --focused)

aerospace list-windows --workspace focused --format '%{window-id}|%{app-name}|%{window-title}' | while IFS='|' read -r wid app title; do
  wid=$(echo "$wid" | xargs)
  app=$(echo "$app" | xargs)
  title=$(echo "$title" | xargs)

  target=$(get_target_workspace "$app" "$title")

  if [ -n "$target" ] && [ "$target" != "$CURRENT_WS" ]; then
    aerospace move-node-to-workspace --window-id "$wid" "$target"
  fi
done
