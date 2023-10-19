symlink fonts for flatpak
ln -s /run/current-system/sw/share/X11/fonts ~/.local/share/fonts
sudo nixos-rebuild switch --flake .#dell-intel --impure --specialisation external-display
