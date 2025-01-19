#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail

# Function to start clipboard monitoring
start_clipboard_monitoring() {
  wl-paste --type text --watch cliphist store &
  wl-paste --type image --watch cliphist store &
}

# Function to restore wallpaper
restore_wallpaper() {
  waypaper --restore &
}

# Function to start system tray utilities
start_system_tray_apps() {
  # Start Waybar in the background
  nohup waybar >/dev/null 2>&1 &

  nm-applet --indicator &

  # Start Bluetooth manager applet
  blueman-applet &
}

# Main function to coordinate startup
main() {
  echo "Starting clipboard monitoring..."
  start_clipboard_monitoring

  echo "Restoring wallpaper..."
  restore_wallpaper

  echo "Launching system tray utilities..."
  start_system_tray_apps

  echo "Startup script completed successfully!"
}

main
