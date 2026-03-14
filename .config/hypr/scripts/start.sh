#!/usr/bin/env bash

set -uo pipefail

LOG_FILE="${LOG_FILE:-/tmp/hyprland.log}"

log() {
  printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE"
}

run_bg() {
  local desc="$1"
  shift
  log "start: ${desc}"
  "$@" >>"$LOG_FILE" 2>&1 &
  local pid=$!
  (
    wait "$pid"
    local rc=$?
    if [ "$rc" -ne 0 ]; then
      log "fail(${rc}): ${desc}"
    fi
  ) &
}

# start_keyring() {
#   # gnome-keyring is started via NixOS/Home Manager service.
#   # Keeping this function as a no-op to avoid hardcoded paths.
#   :
# }

# start_clipboard_monitoring() {
#   run_bg 'wl-paste text' uwsm-app -- wl-paste --type text --watch cliphist store
#   run_bg 'wl-paste image' uwsm-app -- wl-paste --type image --watch cliphist store
# }

start_gui_apps() {
  : # ghostty is managed by home-manager systemd service
}

# setup_system_services() {
#   # systemctl --user enable --now hypridle.service &
#   run_bg 'hyprpolkitagent.service' systemctl --user enable --now hyprpolkitagent.service
#   run_bg 'systemctl --user enable --now hypridle.service'
# }

main() {
  # start_keyring
  # start_clipboard_monitoring
  start_gui_apps
  # setup_system_services
}

main
