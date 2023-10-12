{inputs, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
  isLinux = pkgs.stdenv.isLinux;
in {
  xdg.enable = true;

  home = {
    username = "francois";
    homeDirectory = "/home/francois";
    stateVersion = "23.05";

    packages = with pkgs; [
      btop
      webcord-vencord
      kitty
      lazygit
      gh
      stylua
      lf

      pcmanfm
      gwenview

      obs-studio
      starship

      cliphist
      hyprpicker
      wf-recorder
      wl-clipboard
      xclip

      mongodb-compass
      volta
      wofi
      swww
      neofetch
      networkmanagerapplet

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
    };

    pointerCursor = let
      getFrom = url: hash: name: {
        gtk.enable = true;
        x11.enable = true;
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
  };

  # xdg.configFile = {
  #   "i3/config".text = builtins.readFile ./i3;
  #   "rofi/config.rasi".text = builtins.readFile ./rofi;
  #
  #   # tree-sitter parsers
  #   "nvim/parser/proto.so".source = "${pkgs.tree-sitter-proto}/parser";
  #   "nvim/queries/proto/folds.scm".source =
  #     "${sources.tree-sitter-proto}/queries/folds.scm";
  #   "nvim/queries/proto/highlights.scm".source =
  #     "${sources.tree-sitter-proto}/queries/highlights.scm";
  #   "nvim/queries/proto/textobjects.scm".source =
  #     ./textobjects.scm;
  # } // (if isLinux then {
  #   "ghostty/config".text = builtins.readFile ./ghostty.linux;
  # } else {});

  # programs.fish = {
  #   enable = true;
  # };

  programs.kitty = {
    #   enable = true;
    extraConfig = builtins.readFile ./kitty;
  };

  services.gpg-agent = {
    enable = isLinux;
    # pinentryFlavor = "tty";
    defaultCacheTtl = 31536000;
    maxCacheTtl = 31536000;
  };

  services = {
    mako = {
      enable = true;
      font = "JetBrainsMono 10";
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha-Compact-Pink-Dark";
      package = pkgs.catppuccin-gtk.override {
        accents = ["pink"];
        size = "compact";
        tweaks = ["rimless" "black"];
        variant = "mocha";
      };
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
  };

  programs = {
    git = {
      enable = true;
      lfs.enable = true;
    };
    home-manager.enable = true;
  };

  # xresources.extraConfig = builtins.readFile ./Xresources;
}
