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
      ansible
      mqttx
      tagstudio

      gnome-calculator
      hyprcursor
      asdf-vm
      # stremio
      bitwarden-desktop

      slack
      discord
      galaxy-buds-client

      font-manager

      firefox
      chromium

      inkscape-with-extensions
      gimp3-with-plugins
      kdePackages.gwenview

      protonvpn-gui

      evince
      ffmpeg
      libreoffice-fresh
      postman
      obs-studio
      spotify

      mindustry

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

      # aws-sam-cli # broken
      awscli2
      ssm-session-manager-plugin

      mongodb-compass

      libsecret

      gtk4
      adwaita-icon-theme
      gnome-themes-extra
      adwaita-qt
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

  xdg.desktopEntries = {
    mongodb-compass = {
      name = "MongoDB Compass (Wayland)";
      comment = "The MongoDB GUI";
      genericName = "MongoDB Compass";
      exec = "env XDG_SESSION_TYPE=wayland OZONE_PLATFORM_HINT=wayland mongodb-compass --ignore-additional-command-line-flags --enable-features=UseOzonePlatform --ozone-platform=wayland";
      type = "Application";
      icon = "mongodb-compass";
      startupNotify = true;
      terminal = false;
      categories = ["Development" "Utility" "GTK"];
      mimeType = ["x-scheme-handler/mongodb" "x-scheme-handler/mongodb+srv"];
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
    gnome-keyring = {
      enable = true;
    };
    hyprpolkitagent = {
      enable = true;
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
      # package = pkgs.waybar_git;
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
