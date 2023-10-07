#!/usr/bin/env bash

# Initialize wallpaper daemon
swww init &

# set wallpaper
swww img ~/Wallpapers/mountain.jpg &
# NetworkManager Applet
nm-applet --indicator &

# The bar
waybar &
