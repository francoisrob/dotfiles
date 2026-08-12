#!/usr/bin/env bash
# Gaming-mode toggle, driven by feral gamemode's custom start/end hooks
# (programs.gamemode.settings.custom in the NixOS config).
#
#   gaming-mode.sh on   -> strip Hyprland eye-candy
#   gaming-mode.sh off  -> restore eye-candy
#
# Why this shape, on THIS machine (Optimus laptop, Intel iGPU composites the
# desktop AND the game's output; the NVIDIA MX350 only renders offloaded games):
#
#  * Eye-candy (blur x2 / shadows / animations) is the expensive compositor work
#    on the Intel iGPU. It toggles cleanly at runtime via `hyprctl`.
set -u

# gamemoded may invoke us with a stripped environment; guarantee XDG_RUNTIME_DIR
# so the Hyprland socket lookup below works.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# --- locate the Hyprland socket (gamemoded runs us without HYPRLAND_INSTANCE_SIGNATURE)
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
    # `hyprctl reload` re-reads hyprland.conf -> restores blur/shadows/animations/dim.
    [ -n "$hyprctl" ] && "$hyprctl" reload
    ;;
  *)
    echo "usage: $0 on|off" >&2
    exit 1
    ;;
esac
