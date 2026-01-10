#!/usr/bin/env bash

set -uo pipefail

LOG_FILE="${LOG_FILE:-/tmp/hyprland.log}"

log() {
  echo "$*" | tee -a "$LOG_FILE"
}

eval "$(/usr/bin/gnome-keyring-daemon --start)"
export SSH_AUTH_SOCK

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
  #2>&1 | tee -a "$LOG_FILE" || true
  systemctl --user enable --now hypridle.service &
  hypridle &
}

main() {
  setup_system_services
  start_clipboard_monitoring
  restore_wallpaper
  start_system_tray_apps
  uwsm app -- ghostty --gtk-single-instance=true --quit-after-last-window-closed=false --initial-window=true #2>&1 | tee -a "$LOG_FILE" || true
}

main
