#!/bin/sh
# Hide the bar when certain fullscreen apps are focused

case "$INFO" in
"DaVinci Resolve" | "VirtualBox")
  sketchybar --bar hidden=on
  ;;
*)
  sketchybar --bar hidden=off
  ;;
esac
