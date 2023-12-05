{inputs, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
 pointerCursor = let
   getFrom = url: hash: name: {
     name = name;
     size = 24;
     package = pkgs.runCommand "moveUp" {} ''
       mkdir -p $out/share/icons
       ln -s ${pkgs.fetchzip {
         url = url;
         hash = hash;
       }} $out/share/icons/${name}
     '';
   };
 in
   getFrom
   "https://github.com/catppuccin/cursors/releases/download/v0.2.0/Catppuccin-Mocha-Light-Cursors.zip"
   "sha256-evV5fBi8QYIEvd3ISGHo1NtJg4JdEH7dX1Sr3m5ODls="
   "Catppuccin-Mocha-Light-Cursors";
in {
  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "23.05";
    packages = with pkgs; [
      gnome.gnome-calculator

      xfce.thunar
      xfce.thunar-volman

      kitty

      webcord-vencord
      stable.chromium
      firefox-wayland

      inkscape
      gwenview
      gimp-with-plugins
      okular
      ffmpeg
      libreoffice-fresh

      btop

      nix-index
      prefetch-npm-deps
      nix-prefetch-git
      nix-prefetch

      pass-wayland

      obs-studio
      starship

      swww
      mako
      cliphist
      wf-recorder
      wl-clipboard
      nwg-displays
      networkmanagerapplet

      ncdu
      waypaper

      # Develop
      gh
      git-filter-repo
      lazygit
      nodejs_20
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
    pointerCursor = pointerCursor;
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
    spotifyd = {
      enable = true;
      settings = {
        global = {
          username = "";
          password = "";
        };
      };
    };
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
  };

  gtk = {
    enable = true;
   #theme = {
    # name = "Catppuccin-Mocha-Compact-Pink-Dark";
    # package = pkgs.catppuccin-gtk.override {
    #   accents = ["pink"];
    #   size = "compact";
    #   tweaks = ["rimless"];
    #   variant = "mocha";
    # };
   #};
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
    platformTheme = "gtk";
    enable = true;
    style.name = "Fusion";

    style.package = pkgs.adwaita-qt6;
  };

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    home-manager.enable = true;
  };
}
