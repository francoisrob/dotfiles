{ pkgs, ... }:
let
  nixpkgs-unstable = pkgs.unstable;
in
{
  fonts.packages = with pkgs; [
      (nixpkgs-unstable.nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
      noto-fonts
    ];
}

