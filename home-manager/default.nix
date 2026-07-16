{
  pkgs,
  user,
  ...
}: let
  # One binding so gtk.theme and gtk4.theme can never drift apart.
  # The package is upstream's theme with its Gruvbox Material accents recolored
  # to the original morhetz palette; see modules/pkgs/gruvbox-gtk-morhetz. The
  # "teal" variant is what carries the accent, which is now aqua #8ec07c.
  gruvboxGtk = {
    name = "Gruvbox-Teal-Dark-Medium";
    package = pkgs.gruvbox-gtk-morhetz;
  };
in {
  imports = [
    ./spotify-player.nix
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
      # markdown LSP — Mason's .NET single-file build SIGABRTs on NixOS, so
      # nvim is configured with `marksman.mason = false` to use this one
      marksman
      (python3.withPackages (ps: with ps; [ pytest ]))
      mqttx
      # aws-sam-cli  # TODO: re-enable when nixpkgs fixes jmespath~=1.0.1 vs 1.1.0 mismatch

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
  };

  gtk = {
    enable = true;
    # Gruvbox Dark, medium contrast: the "medium" tweak sets the background to
    # #282828, and the accent is aqua #8ec07c, matching hyprland/kitty/wayle.
    theme = gruvboxGtk;

    # Since home-manager 26.05, gtk4.theme no longer defaults to gtk.theme, so
    # at stateVersion 26.05 it is null and GTK 4 apps get no theme at all.
    # Setting it writes ~/.config/gtk-4.0/gtk.css, which @imports the theme.
    # That is the only route that works for libadwaita apps (gnome-calculator),
    # since they ignore gtk-theme-name entirely.
    gtk4.theme = gruvboxGtk;

    # Drives gtk-application-prefer-dark-theme for GTK 3 and
    # gtk-interface-color-scheme=2 for GTK 4. Without it GTK 4 has no dark
    # preference, so libadwaita renders light regardless of the theme.
    colorScheme = "dark";

    iconTheme = {
      name = "Gruvbox-Plus-Dark";
      package = pkgs.gruvbox-plus-icons.override {
        # Ignore the names: this pack's "jade" is gruvbox blue (#076678/#458588)
        # and its "green" is the aqua ramp (#427b58/#689d6a/#8ec07c), which is the
        # accent used across hyprland, kitty, wayle and Kvantum.
        folder-color = "green";
      };
    };
    font = {
      name = "Sans";
      size = 11;
    };
  };

  # Qt goes through Kvantum rather than following GTK, so Qt apps get the same
  # gruvbox medium background and aqua accent as everything else instead of
  # adwaita-dark's blue. platformTheme "qtct" sets QT_QPA_PLATFORMTHEME=qt5ct,
  # which qt6ct also answers to, so Qt5 and Qt6 apps (gwenview) both follow.
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

    # qt5ct/qt6ct own the icon theme and the widget style for Qt apps; without
    # this they fall back to their own default style and ignore Kvantum.
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
