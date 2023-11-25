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
      # gnome.adwaita-icon-theme
      gnome.nautilus

      xfce.thunar
      xfce.thunar-volman

      # ngrok
      inkscape
      okular
      btop
      webcord-vencord
      discord
      git-filter-repo
      kitty
      lazygit
      gh
      stylua
      lf
      libreoffice-fresh
      firefox-wayland

      gimp-with-plugins

      stable.chromium
      #
      nwg-displays
      ffmpeg
      nix-index
      prefetch-npm-deps
      nix-prefetch-git
      nix-prefetch

      pass-wayland

      mako
      # pcmanfm
      gwenview

      obs-studio
      starship

      cliphist
      hyprpicker
      wf-recorder
      wl-clipboard

      volta
      wofi
      swww
      networkmanagerapplet

      ncdu
      waypaper

      sqlitebrowser

      (inputs.hyprland-contrib.packages.${pkgs.system}.grimblast)
      (
        waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
        })
      )
    ];

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      EDITOR = "nvim";
      PAGER = "less -FirSwX";
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs; [stdenv.cc.cc openssl]);
      NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = 1;

      GDK_BACKEND = "wayland";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";
      TERMINAL = "kitty";
      # XDG_CURRENT_DESKTOP = "Hyprland";
      # GDK_BACKEND = "wayland";
      # VISUAL = "nvim";
      # MANPAGER = "nvim +Man!";
      # TERMINAL = "kitty";
    };
    pointerCursor = pointerCursor;
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhs;
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
    theme = {
      name = "Catppuccin-Mocha-Compact-Pink-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["pink"];
        size = "compact";
        tweaks = ["rimless"];
        variant = "mocha";
      };
    };
    iconTheme = {
      package = pkgs.vimix-icon-theme;
      name = "Vimix";
    };
    cursorTheme = pointerCursor;
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
