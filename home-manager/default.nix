{
  pkgs,
  user,
  inputs,
  ...
}: let
  serena = inputs.serena.packages.${pkgs.stdenv.hostPlatform.system}.serena;
in {
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "24.11";

    packages = with pkgs; [
      ansible
      mqttx
      serena

      gnome-calculator
      grayjay
      bitwarden-desktop

      slack
      discord

      font-manager

      firefox
      chromium
      google-chrome

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

      wl-clipboard

      ncdu
      gh
      lazygit
      uv

      awscli2
      ssm-session-manager-plugin

      mongodb-compass

      libsecret

      gtk3
      gtk4
      adwaita-icon-theme
      gnome-themes-extra
      adwaita-qt
    ];

    sessionVariables = {
      TERMINAL = "ghostty";
      XDG_DATA_DIRS = "${pkgs.lib.makeSearchPath "share" ["/var/lib/flatpak/exports" "/home/${user}/.local/share/flatpak/exports"]}:$XDG_DATA_DIRS";
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

  xdg.autostart.enable = true;
  xdg.configFile = {
    "xdg-desktop-portal/hyprland-portals.conf".text = ''
      [preferred]
      default=hyprland;gtk
    '';
  };
  xdg.dataFile = {
    "flatpak/overrides/global".text = ''
      [Context]
      filesystems=~/.icons:ro;~/.themes:ro
    '';
  };
  xdg.desktopEntries = {
    mongodb-compass = {
      name = "MongoDB Compass (Wayland)";
      comment = "The MongoDB GUI";
      genericName = "MongoDB Compass";
      exec = "env XDG_SESSION_TYPE=wayland OZONE_PLATFORM_HINT=wayland mongodb-compass --ignore-additional-command-line-flags --enable-features=UseOzonePlatform --ozone-platform=wayland --password-store=gnome-libsecret";
      type = "Application";
      icon = "mongodb-compass";
      startupNotify = true;
      terminal = false;
      categories = ["Development" "Utility" "GTK"];
      mimeType = ["x-scheme-handler/mongodb" "x-scheme-handler/mongodb+srv"];
    };
  };
  services = {
    kanshi.enable = true;
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
    hyprpolkitagent.enable = true;
    hypridle.enable = true;
    cliphist.enable = true;
    hyprpaper.enable = true;
    swaync.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = 1;
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
      name = "gtk3";
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
        cursor-theme = "Bibata-Modern-Classic";
        cursor-size = 24;
        icon-theme = "Papirus";
      };
    };
  };

  programs = {
    spotify-player.enable = true;
    waybar = {
      enable = true;
      systemd.enable = true;
    };
    ghostty = {
      enable = true;
      enableFishIntegration = true;
      systemd.enable = true;
      settings = {
        theme = "Catppuccin Mocha";
        font-family = "JetBrainsMono Nerd Font";
        font-size = 13;
        window-padding-x = 8;
        window-padding-y = 4;
        window-decoration = false;
        gtk-titlebar = false;
        cursor-style = "block";
        cursor-style-blink = false;
        mouse-hide-while-typing = true;
        confirm-close-surface = false;
        copy-on-select = "clipboard";
        desktop-notifications = true;
      };
    };
    git = {
      enable = true;
      settings = {
        user = {
          name = "Francois Robbertze";
          email = "67432234+francoisrob@users.noreply.github.com";
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
      lfs = {
        enable = true;
      };
    };
    mise = {
      enable = true;
      enableFishIntegration = true;
    };
    fzf = {
      enable = true;
      enableFishIntegration = true;
      defaultCommand = "fd --type file --follow --hidden --exclude .git";
      changeDirWidgetCommand = "fd --type directory --follow --hidden --exclude .git";
      fileWidgetCommand = "fd --type file --follow --hidden --exclude .git";
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    starship = {
      enable = true;
      enableFishIntegration = true;
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
