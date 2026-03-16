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
      # Developer
      chafa
      gnumake
      mongosh
      mongodb-tools

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
      package = with pkgs; neovim;
    };
  };
}
