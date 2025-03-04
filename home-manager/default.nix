{pkgs, ...}: {
  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "24.11";

    packages = with pkgs; [
      gnome-calculator
      hyprcursor
      asdf-vm
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

      stylua
      aws-sam-cli

      mongodb-compass

      (waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ ["-Dexperimental=true"];
      }))
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    # either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/francois/etc/profile.d/hm-session-vars.sh
    #
    sessionVariables = {
      TERMINAL = "kitty";
    };

    shell = {
      enableFishIntegration = true;
    };

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
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
    platformTheme.name = "adwaita";
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
    git = {
      enable = true;
      lfs.enable = true;
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };
}
