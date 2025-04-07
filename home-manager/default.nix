{
  pkgs,
  user,
  inputs,
  ...
}: let
  tagstudio = inputs.tagstudio.packages.${pkgs.stdenv.hostPlatform.system}.tagstudio;
in {
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "24.11";

    packages = with pkgs; [
      tagstudio

      gnome-calculator
      hyprcursor
      asdf-vm
      stremio
      bitwarden

      slack
      discord

      font-manager

      firefox-wayland
      chromium

      inkscape
      gimp
      kdePackages.gwenview

      evince
      ffmpeg
      libreoffice-fresh
      postman
      obs-studio
      spotify

      swww
      swaynotificationcenter
      pass-wayland
      cliphist
      wl-clipboard

      nwg-look
      networkmanagerapplet

      waypaper

      starship
      ncdu
      gh
      lazygit

      aws-sam-cli

      mongodb-compass

      # *** AI ***
      adwaita-qt # Qt style matching Adwaita
      libsForQt5.qtstyleplugins
    ];

    sessionVariables = {
      TERMINAL = "kitty";
    };

    pointerCursor = {
      gtk = {
        enable = true;
      };
      x11 = {
        enable = true;
      };
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };
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
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus";
      package = pkgs.catppuccin-papirus-folders.override {
        accent = "blue";
        flavor = "mocha";
      };
    };
    font = {
      name = "Sans";
      size = 11;
    };
  };

  qt = {
    enable = true;
    platformTheme = {
      name = "gtk";
    };
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Adwaita-dark";
        color-scheme = "prefer-dark";
      };
    };
  };

  programs = {
    waybar = {
      enable = true;
      package = pkgs.waybar_git;
    };

    git = {
      enable = true;
      lfs = {
        enable = true;
      };
    };

    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };

    # Let Home Manager install and manage itself.
    home-manager = {
      enable = true;
    };
  };
}
