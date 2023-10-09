{ lib, pkgs, ... }:

{
  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "23.05";

    packages = with pkgs; [
      btop
      webcord-vencord
      kitty
      lazygit
      gh
      stylua
      lf

      obs-studio
      starship

      cliphist
      wf-recorder
      wl-clipboard
      xclip

      mongodb-compass
      volta
      rofi-wayland
      swww
      neofetch
      networkmanagerapplet
      (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
       })
      )
    ];
    sessionVariables = {
      EDITOR = "nvim";
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [ stdenv.cc.cc openssl ]);
      NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
    };
  };
  services = {
    mako = {
      enable = true;
      font = "Fira Code Normal 9";
    };
  };
  programs.home-manager.enable = true;
}
