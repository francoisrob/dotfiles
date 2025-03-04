{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      kanshi

      fastfetch
      unzip
      neovim

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
      gnumake
      ripgrep
      mongosh
      mongodb-tools
      mono

      lua
      luajitPackages.luarocks
      go
      python3
      cargo

      nixd
      alejandra

      # C development tools
      gcc
      gdb
      cmake
      check
      valgrind

      # Build essentials
      binutils
      pkg-config

      # Optional but useful
      bear # For generating compile_commands.json
      clang-tools # For clangd, static analysis, etc.
    ];
  };
}
