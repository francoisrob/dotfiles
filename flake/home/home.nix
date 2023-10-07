{ config, pkgs, ... }:

{
  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "23.05";

    packages = with pkgs; [
      firefox
      btop
      webcord-vencord
      kitty
      lazygit
      gh
      lf
      starship
      nodejs
      rofi-wayland
      swww
      networkmanagerapplet
      wl-clipboard
      
      (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
       })
      )

    # #User Apps
    # celluloid
    # discord
    # librewolf
    # cool-retro-term
    # bibata-cursors
    # vscode
    # lollypop
    #
    # #utils
    # ranger
    # wlr-randr
    # gnumake
    # catimg
    # curl
    # appimage-run
    # xflux
    # dunst
    # pavucontrol

    # cava
    # neovim
    # nano
    # rofi
    # nitch
    # wget
    # grim
    # slurp
    # pamixer
    # mpc-cli
    # tty-clock
    # exa
    # btop
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
    # enable = true;
  # };

}
