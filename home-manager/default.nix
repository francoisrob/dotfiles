{
  pkgs,
  user,
  ...
}: {
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "26.05";

    packages = with pkgs; [
      awww
      cava

      ansible
      ansible-lint
      sops
      age
      yamllint
      shellcheck
      (python3.withPackages (ps: with ps; [ pytest ]))
      mqttx
      aws-sam-cli

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

      proton-vpn

      evince
      ffmpeg
      libreoffice-fresh
      postman
      obs-studio
      stremio-linux-shell
      spotify

      wl-clipboard

      ncdu
      gh
      lazygit
      just
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

  xdg = {
    autostart.enable = true;
    configFile = {
      "xdg-desktop-portal/hyprland-portals.conf".text = ''
        [preferred]
        default=hyprland;gtk
      '';
    };
    dataFile = {};
    desktopEntries = {
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
  };
  systemd.user = {
    services.hyprsunset-on = {
      Unit.Description = "Enable hyprsunset night light";
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset -t 4500";
        Restart = "on-failure";
      };
    };
    timers.hyprsunset-on = {
      Unit.Description = "Enable hyprsunset at 19:00";
      Timer = {
        OnCalendar = "*-*-* 19:00:00";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
    services.hyprsunset-off = {
      Unit.Description = "Disable hyprsunset night light";
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.procps}/bin/pkill hyprsunset";
      };
    };
    timers.hyprsunset-off = {
      Unit.Description = "Disable hyprsunset at 07:00";
      Timer = {
        OnCalendar = "*-*-* 07:00:00";
        Persistent = true;
      };
      Install.WantedBy = ["timers.target"];
    };
  };

  services = {
    kanshi.enable = true;
    wayle.enable = true;
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
    hyprpolkitagent.enable = true;
    hypridle.enable = true;
    cliphist.enable = true;
    # hyprpaper replaced by wayle wallpaper engine
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
