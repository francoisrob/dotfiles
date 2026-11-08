{
  pkgs,
  user,
  ...
}: let
  gruvboxGtk = {
    name = "Gruvbox-Teal-Dark-Medium";
    package = pkgs.gruvbox-gtk-morhetz;
  };
in {
  imports = [
    ./claude-remote-control.nix
    ./spotify-player.nix
    ./ai.nix
    ./session.nix
  ];

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
      marksman
      (python3.withPackages (ps: with ps; [pytest]))
      mqttx

      gnome-calculator
      grayjay
      bitwarden-desktop

      slack
      discord

      claude-desktop-fhs

      grok-bot

      font-manager

      firefox
      chromium
      networkmanagerapplet

      inkscape-with-extensions
      gimp3-with-plugins
      kdePackages.gwenview

      proton-vpn

      evince
      ffmpeg
      libreoffice
      postman
      obs-studio
      stremio-linux-shell
      spotify

      wl-clipboard

      ncdu
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
    ];

    pointerCursor = {
      enable = true;
      gtk = {
        enable = true;
      };
      x11 = {
        enable = true;
      };
      package = pkgs.bibata-cursors;
      hyprcursor = {
        enable = true;
      };
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

  services = {
    wayle.enable = true;
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 31536000;
      maxCacheTtl = 31536000;
    };
    hyprpolkitagent.enable = true;
    hypridle.enable = true;
    cliphist.enable = true;
  };

  gtk = {
    enable = true;
    theme = gruvboxGtk;

    colorScheme = "dark";

    gtk4 = {
      theme = gruvboxGtk;

      colorScheme = null;
      extraConfig = {
        gtk-interface-color-scheme = "dark";
      };
    };

    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons.override {
        folder-color = "green";
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
      name = "qtct";
    };
    style = {
      name = "kvantum";
    };
    kvantum = {
      enable = true;
      themes = [pkgs.gruvbox-kvantum-medium];
      settings = {
        General = {
          theme = "Gruvbox-Dark-Medium";
        };
      };
    };

    qt5ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "Gruvbox-Plus-Dark";
        standard_dialogs = "xdgdesktopportal";
      };
    };
    qt6ctSettings = {
      Appearance = {
        style = "kvantum";
        icon_theme = "Gruvbox-Plus-Dark";
        standard_dialogs = "xdgdesktopportal";
      };
    };
  };

  dconf = {
    settings = {
      "org/gnome/desktop/interface" = {
        gtk-theme = "Gruvbox-Teal-Dark-Medium";
        color-scheme = "prefer-dark";
        cursor-theme = "Bibata-Modern-Classic";
        cursor-size = 24;
        icon-theme = "Gruvbox-Plus-Dark";
      };
    };
  };

  programs = {
    dbeaver.enable = true;
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
      lfs.enable = true;
      ignores = [
        "**/.claude/settings.local.json"
        "**/.claude/plans/"
        "**/.claude/worktrees/"
      ];
    };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
      settings = {
        git_protocol = "https";
        aliases = {
          co = "pr checkout";
        };
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
      changeDirWidget.command = "fd --type directory --follow --hidden --exclude .git";
      fileWidget.command = "fd --type file --follow --hidden --exclude .git";
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

    home-manager = {
      enable = true;
    };
  };
}
