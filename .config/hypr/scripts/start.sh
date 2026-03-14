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

start_gui_apps() {
  : # ghostty is managed by home-manager systemd service
}

main() {
  start_gui_apps
}

main
