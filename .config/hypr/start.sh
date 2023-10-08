#!/usr/bin/env bash

# Initialize wallpaper daemon
swww init &

# set wallpaper
swww img ~/Wallpapers/mountain.jpg &
# NetworkManager Applet
nm-applet --indicator &

# The bar
waybar &

dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP &
