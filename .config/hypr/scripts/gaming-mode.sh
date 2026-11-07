#!/usr/bin/env bash
set -u

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  for base in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" /tmp/hypr; do
    [ -d "$base" ] || continue
    for dir in "$base"/*/; do
      [ -S "${dir}.socket.sock" ] || continue
      HYPRLAND_INSTANCE_SIGNATURE="$(basename "$dir")"; export HYPRLAND_INSTANCE_SIGNATURE
      break 2
    done
  done
fi
hyprctl="$(command -v hyprctl)" || hyprctl=""

case "${1:-}" in
  on)
    [ -n "$hyprctl" ] && "$hyprctl" --batch \
      "keyword decoration:blur:enabled false ; keyword decoration:shadow:enabled false ; keyword decoration:dim_inactive false ; keyword animations:enabled false"
    ;;
  off)
    [ -n "$hyprctl" ] && "$hyprctl" reload
    ;;
  *)
    echo "usage: $0 on|off" >&2
    exit 1
    ;;
esac
