{pkgs, ...}: {
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

      ripgrep
      sd
      fd
      bat
      jq
      broot

      mpv

      lutris

      scrcpy

      # The -fhs variant, not the bare one: MCP servers are spawned by the app
      # as plain `npx`/`uvx` commands against FHS paths, which only resolve
      # inside the buildFHSEnv. It pulls in qemu_kvm + virtiofsd + OVMF for
      # Cowork's VM gate, so the closure is ~1.5G larger than the bare package.
      claude-desktop-fhs

      # Developer
      chafa
      gnumake
      mongosh
      mongodb-tools

      # System-level rather than in home-manager so it is on PATH straight
      # after `nixos-rebuild switch`, without waiting for a home activation.
      # That matters on a fresh machine, where it would otherwise be the one
      # tool you need to bootstrap the machine but cannot run yet. Unfree, but
      # modules/nixpkgs-config.nix already sets allowUnfree.
      # git was previously only present via home-manager's programs.git, so a
      # freshly installed host had no git until after `make home` -- awkward,
      # since cloning this repo is what gets you there. home-manager still owns
      # the *config* (user, aliases, lfs); this is just the binary.
      git

      mono
      sqlite
      sqlitebrowser
      imagemagick
      bluetuith

      socat
      bubblewrap
    ];
  };

  system.activationScripts.binbash = ''
    ln -sfn ${pkgs.bash}/bin/bash /bin/bash
  '';

  system.activationScripts.usrbinsh = ''
    mkdir -p /usr/bin
    ln -sfn ${pkgs.bash}/bin/sh /usr/bin/sh
  '';

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
      package = pkgs.neovim;
    };
  };
}
