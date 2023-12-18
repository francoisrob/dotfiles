{ inputs, pkgs, ... }:
{
  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "23.11";

    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })

      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      gnome.gnome-calculator

      starship

      # (stable.discord.override {
      #   withOpenASAR = true;
      #   withVencord = true;
      # })

      webcord-vencord
      font-manager

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

      obs-studio

      swww
      mako
      pass-wayland
      cliphist
      wl-clipboard

      nwg-displays
      networkmanagerapplet

      ncdu
      waypaper

      # Develop
      gh
      git-filter-repo
      lazygit
      sqlitebrowser
      stylua

      # wf-recorder
      (inputs.hyprland-contrib.packages.${pkgs.system}.grimblast)
      (
        waybar.overrideAttrs (oldAttrs: {
          mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
        })
      )
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
      # EDITOR = "emacs";
      LANG = "en_US.UTF-8";
      LANGUAGE = "en_US";
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

    pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Original-Ice";
      size = 16;
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
      name = "rose-pine";
      package = pkgs.rose-pine-gtk-theme;
    };
    iconTheme = {
      name = "rose-pine";
      package = pkgs.rose-pine-icon-theme;
    };
    font = {
      name = "Sans";
      size = 11;
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
