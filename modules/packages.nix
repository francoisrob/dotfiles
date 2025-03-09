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

      (lutris.override {
        extraLibraries = pkgs: [
          findutils # List library dependencies here
        ];
        extraPkgs = pkgs: [
          # List package dependencies here
        ];
      })

      # Developer
      tmux

      fd
      fzf
      ripgrep

      chafa

      gnumake
      mongosh
      mongodb-tools
      mono
    ];
  };
}
