{ config, pkgs, ... }:

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
      starship
      nodejs
      rofi-wayland
      swww
      neofetch
      slack
      networkmanagerapplet
      (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
       })
      )
    ];

    file = {
      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
      # ".config/nvim/lua/custom" = {
      #   source = ./nvim.lua.custom;
      #   recursive = true;
      # };
    };

    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs.home-manager.enable = true;
  # services.dunst = {
  #   enable = true;
  # };
  # wayland.windowManager.sway = {
  #     enable = true;
  #     config = rec {
  #         modifier = "Mod4";
  #         terminal = "kitty";
  #       };
  #   };
}
