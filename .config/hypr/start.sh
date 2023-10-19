#!/usr/bin/env bash

# swww init &
# swww img ~/Wallpapers/mocha_mountain.jpg &

waypaper --restore &

waybar &

nm-applet --indicator &
blueman-applet &
# blueman-tray &

# The bar

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
# dbus-update-activation-environment --systemd --all
# systemctl --user import-environment QT_QPA_PLATFORMTHEME
