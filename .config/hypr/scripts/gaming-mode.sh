#!/usr/bin/env bash
# Gaming-mode toggle, driven by feral gamemode's custom start/end hooks
# (programs.gamemode.settings.custom in the NixOS config).
#
#   gaming-mode.sh on   -> secondary monitor to 60Hz + strip Hyprland eye-candy
#   gaming-mode.sh off  -> secondary back to 120Hz + restore eye-candy
#
# Why this shape, on THIS machine (Optimus laptop, Intel iGPU composites the
# desktop AND the game's output; the NVIDIA MX350 only renders offloaded games):
#
#  * Eye-candy (blur x2 / shadows / animations) is the expensive compositor work
#    on the Intel iGPU. It toggles cleanly at runtime via `hyprctl`.
#  * The secondary's REFRESH cannot be changed at runtime on this stack
#    (Hyprland 0.55 + kanshi + dock): hyprctl modesets are overridden by kanshi's
#    wlr-output-management config, and runtime clients (kanshictl, wlr-randr) hang
#    waiting for an apply-ack Hyprland never sends. The ONLY mechanism that applies
#    is editing kanshi's config and restarting the service -> that's what we do.
#    Cost: a brief monitor re-mode flash on game start and exit.
#
# kanshi config is hand-maintained at ~/.config/kanshi/config (NOT a read-only
# home-manager symlink). We toggle exactly one line: the docked profile's
# secondary ($right-dell) output. If you ever move kanshi to
# `services.kanshi.settings`, that file becomes read-only and this sed will fail.
set -u

# gamemoded may invoke us with a stripped environment. `systemctl --user` (used to
# restart kanshi) finds the user bus via $XDG_RUNTIME_DIR when DBUS_SESSION_BUS_ADDRESS
# is unset, so guarantee XDG_RUNTIME_DIR is present or the refresh-down silently no-ops.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

KANSHI_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/kanshi/config"
REPL_60='    output $right-dell mode 2560x1440@60Hz position 2560,0'
REPL_120='    output $right-dell position 2560,0'

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

# Flip the secondary's mode in kanshi's config, then restart kanshi to apply it.
set_secondary() { # $1 = 60 | 120
  [ -f "$KANSHI_CONF" ] && [ -w "$KANSHI_CONF" ] || return 0
  case "$1" in
    60)  sed -i 's|^[[:space:]]*output [$]right-dell.*|'"$REPL_60"'|'  "$KANSHI_CONF" ;;
    120) sed -i 's|^[[:space:]]*output [$]right-dell.*|'"$REPL_120"'|' "$KANSHI_CONF" ;;
  esac
  systemctl --user restart kanshi 2>/dev/null || true
}

case "${1:-}" in
  on)
    set_secondary 60
    [ -n "$hyprctl" ] && "$hyprctl" --batch \
      "keyword decoration:blur:enabled false ; keyword decoration:shadow:enabled false ; keyword decoration:dim_inactive false ; keyword animations:enabled false"
    ;;
  off)
    set_secondary 120
    # `hyprctl reload` re-reads hyprland.conf -> restores blur/shadows/animations/dim.
    [ -n "$hyprctl" ] && "$hyprctl" reload
    ;;
  *)
    echo "usage: $0 on|off" >&2
    exit 1
    ;;
esac
