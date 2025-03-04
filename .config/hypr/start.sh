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
  uwsm app -- waypaper --restore &
}

# Function to start system tray utilities
start_system_tray_apps() {
  # Start Waybar in the background
  uwsm app -- nohup waybar >/dev/null 2>&1 &

  uwsm app -- nm-applet --indicator &

  # Start Bluetooth manager applet
  uwsm app -- blueman-applet &
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

  uwsm app -- kanshi
  systemctl --user enable --now hyprpolkitagent.service
  systemctl --user enable --now hypridle.service
}

main
