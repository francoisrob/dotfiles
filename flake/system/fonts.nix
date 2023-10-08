{ pkgs, ... }:
let
  nixpkgs-unstable = pkgs.unstable;
in
{
  fonts.fonts = with pkgs; [
    fira-code
    fira-code-symbols
    font-awesome
    font-awesome_4
    font-awesome_5
    (nixpkgs-unstable.nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
    noto-fonts # For microsoft websites like Github and Linkedin on Chromium browsers
  ];
}

