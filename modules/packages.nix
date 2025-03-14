{pkgs, ...}: {
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

      # mpvScripts
      # (self: super: {
      #   mpv = super.mpv.override {
      #     scripts = [self.mpvScripts.mpris];
      #   };
      # })
      (mpv.override {
        scripts = [ mpvScripts.webtorrent-mpv-hook ];
      })

      (lutris.override {
        extraLibraries = pkgs: [
          findutils # List library dependencies here
        ];
        extraPkgs = pkgs: [
          # List package dependencies here
        ];
      })

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
