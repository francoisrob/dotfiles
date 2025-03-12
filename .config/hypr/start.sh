#!/usr/bin/env bash

set -uo pipefail

start_clipboard_monitoring() {
  uwsm app -- wl-paste --type text --watch cliphist store &
  uwsm app -- wl-paste --type image --watch cliphist store &
}

# Function to restore wallpaper
restore_wallpaper() {
  uwsm app -- waypaper --restore &
}

start_system_tray_apps() {
  uwsm app -- waybar &
  uwsm app -- nm-applet --indicator &
  uwsm app -- blueman-applet &
}

setup_system_services() {
  systemctl --user enable --now hyprpolkitagent.service
  systemctl --user enable --now hypridle.service
  # UWSM handles env sync
  # dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
}

main() {
  start_clipboard_monitoring
  restore_wallpaper
  start_system_tray_apps
  uwsm-app -- kanshi &
  setup_system_services
}

main
