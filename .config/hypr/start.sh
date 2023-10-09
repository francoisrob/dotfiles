#!/usr/bin/env bash

# Initialize wallpaper daemon
swww init &

# set wallpaper
swww img ~/Wallpapers/mountain.jpg &
# NetworkManager Applet
nm-applet --indicator &
blueman-tray &

# The bar
waybar &

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
# dbus-update-activation-environment --systemd --all
# systemctl --user import-environment QT_QPA_PLATFORMTHEME
