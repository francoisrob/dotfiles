{inputs, ...}: {
  config,
  lib,
  pkgs,
  ...
}: 
{
  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "23.05";
    packages = with pkgs; [
      gnome.gnome-calculator

      starship

      # discord
      (discord.override {
        # remove any overrides that you don't want
        withOpenASAR = true;
        withVencord = true;
      })
      webcord-vencord

      firefox-wayland

      inkscape
      gwenview
      gimp-with-plugins
      okular
      ffmpeg
      libreoffice-fresh


      nix-index
      prefetch-npm-deps
      nix-prefetch-git
      nix-prefetch

      pass-wayland

      obs-studio

      swww
      mako
      cliphist
      wl-clipboard

      wf-recorder
      nwg-displays
      networkmanagerapplet

      ncdu
      waypaper

      # Develop
      gh
      git-filter-repo
      lazygit
      # volta
      sqlitebrowser
      stylua

      (inputs.hyprland-contrib.packages.${pkgs.system}.grimblast)
      (
        waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
        })
      )
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LANGUAGE="en_US";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = 1;
      GDK_BACKEND = "wayland";

      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";
      TERMINAL = "kitty";
    };
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
  };

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = [pkgs.rofi-emoji];
    configPath = ".config/rofi/config.rasi";
    theme = "gruvbox.rasi";
  };

  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Juno";
      package = pkgs.juno-theme;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    gtk3.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
    gtk4.extraConfig = {
      Settings = ''
        gtk-application-prefer-dark-theme=1
      '';
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk2";
    style = "gtk2";
  };

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    home-manager.enable = true;
  };
}
