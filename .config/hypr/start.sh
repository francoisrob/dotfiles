#!/usr/bin/env bash

export XDG_SESSION_TYPE=wayland
export WLR_NO_HARDWARE_CURSORS=1
export XCURSOR_SIZE=24

waypaper --restore &
waybar &
nm-applet --indicator &
blueman-applet
