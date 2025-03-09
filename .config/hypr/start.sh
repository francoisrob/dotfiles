#!/usr/bin/env bash

set -uo pipefail

log() {
  echo "[$(date '+%H:%M:%S')] $1"
}

start_clipboard_monitoring() {
  log "Starting cliphist"
  if ! pgrep -f "wl-paste --type text" >/dev/null; then
    wl-paste --type text --watch cliphist store &
  fi

  if ! pgrep -f "wl-paste --type image" >/dev/null; then
    wl-paste --type image --watch cliphist store &
  fi
}

# Function to restore wallpaper
restore_wallpaper() {
  log "Restoring wallpaper"
  uwsm app -- waypaper --restore &
}

start_system_tray_apps() {
  log "Starting tray apps"
  if ! pgrep -x waybar >/dev/null; then
    uwsm app -- nohup waybar >/dev/null 2>&1 &
  fi

  if ! pgrep -x nm-applet >/dev/null; then
    uwsm app -- nm-applet --indicator &
  fi

  if ! pgrep -x blueman-applet >/dev/null; then
    uwsm app -- blueman-applet &
  fi
}

setup_system_services() {
  log "Starting systemd services"
  systemctl --user enable --now hyprpolkitagent.service
  systemctl --user enable --now hypridle.service
  dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
}

main() {

  start_clipboard_monitoring
  restore_wallpaper
  start_system_tray_apps

  uwsm app -- kanshi &

  setup_system_services
}

main
