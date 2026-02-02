{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs = {
    overlays = [
      (self: super: {
        mpv = super.mpv.override {
          scripts = [self.mpvScripts.webtorrent-mpv-hook];
        };

        lutris = super.lutris.override {
          extraLibraries = pkgs: [
            self.findutils
          ];
          extraPkgs = pkgs: [];
        };
      })

      inputs.neovim-nightly.overlays.default
    ];
  };

  nix = {
    settings = {
      substituters = [
        "https://neovim-nightly.cachix.org"
      ];
      trusted-public-keys = [
        "neovim-nightly.cachix.org-1:feIoInHRevVEplgdZvQDjhp11kYASYCE2NGY9hNrwxY="
      ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      sshpass
      php
      ngrok

      fastfetch
      unzip
      popsicle
      gparted

      btop
      icu

      kitty
      zoxide

      ripgrep
      fzf
      sd
      fd
      bat
      jq
      broot

      mpv

      lutris

      scrcpy
      # Developer
      chafa
      gnumake
      mongosh
      mongodb-tools

      mono
      sqlite
      sqlitebrowser
      bluetuith
    ];
  };

  security.wrappers.btop = {
    source = "${pkgs.btop}/bin/btop";
    owner = "root";
    group = "root";
    capabilities = "cap_perfmon,cap_dac_read_search+ep";
  };

  programs = {
    nix-index = {
      enable = true;
      enableFishIntegration = true;
      enableBashIntegration = false;
      enableZshIntegration = false;
    };

    tmux = {
      enable = true;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
      package = with pkgs; neovim;
    };
  };
}
