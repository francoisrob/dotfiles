{pkgs, ...}: {
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
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      kanshi

      fastfetch
      unzip
      # neovim
      popsicle
      gparted

      btop
      icu

      kitty
      zoxide

      mpv

      lutris

      # Developer
      fd
      fzf
      ripgrep

      chafa
      scrcpy

      gnumake
      mongosh
      mongodb-tools
      mono
    ];
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
  };
}
