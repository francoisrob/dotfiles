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
      mongodb-compass
      volta
      # rofi-wayland
      # swww
      neofetch
      slack
      networkmanagerapplet
      # (waybar.overrideAttrs (oldAttrs: {
      #   mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      #  })
      # )
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
    services.picom = {
      activeOpacity = 0.99;
      enable = true;
      backend = "glx";
      # For NVIDIA, we can run with the simpler xrender backend,
      # which does not do vsync
      # Note: This may also need ForceFullCompositionPipeline in xorg.conf
      # See: https://github.com/chjj/compton/issues/227
      # backend = if isNvidia then "xrender" else "glx";
      settings = {
        no-fading-openclose = true;
        invert-color-include = [ "TAG_INVERT@:8c = 1" ];
        };
      fade = true;
      fadeDelta = 12;
      fadeSteps = [ 0.15 0.15 ];
      inactiveOpacity = 0.90;
      menuOpacity = 0.98;
      shadow = true;
      shadowExclude = [
        "n:e:Notification"
        "name = 'cpt_frame_xcb_window'" # Zoom screen sharing
        "class_g ?= 'zoom'" # Zoom screen sharing
        ];
      shadowOffsets = [ (-15) (-15) ];
      shadowOpacity = 0.7;
      opacityRules = [
        "80:class_i ?= 'rofi'"
        "100:class_g ?= 'firefox'"
        "100:class_i ?= 'firefox'"
      ];
      };
}
