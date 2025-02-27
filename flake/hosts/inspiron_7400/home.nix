{
  inputs,
  pkgs,
  ...
}: {
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

      nwg-displays
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
    fish = {
      enable = true;
      shellInit = ''
         set fish_greeting ""
         set fish_home ~/.config/fish

         set -gx PATH "$HOME/.local/share/bin/" $PATH
         set -gx PATH "$HOME/.local/bin/" $PATH

         # Volta
         set -gx VOLTA_HOME "$HOME/.volta"
         set -gx PATH "$VOLTA_HOME/bin" $PATH

         # Rust
         set -gx PATH "$HOME/.cargo/bin" $PATH

         # Bun
         set -gx PATH "$HOME/.bun/bin" $PATH

         # set -gx EDITOR nvim
         # set -gx VISUAL nvim

         set -gx FZF_DEFAULT_COMMAND 'fd --type file'
         set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND

         starship init fish | source
         zoxide init fish | source

         source "$HOME/.local/state/nix/profiles/home-manager/home-path/share/asdf-vm/asdf.fish"

         function dev-api -d "npm run dev-api in current directory"
             npm run dev-api
        end

         function fish_user_key_bindings
             fish_default_key_bindings -M insert
             fish_vi_key_bindings --no-erase insert
         end

         source ~/.secrets.fish
      '';
    };
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
  };
}
