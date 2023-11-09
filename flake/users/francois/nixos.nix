{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["ntfs"];
  };
  console = {
    keyMap = "us";
    font = "Lat2-Terminus16";
  };
  environment = {
    systemPackages = with pkgs; [
      vimix-gtk-themes
      vimix-icon-theme

      qt5ct
      libsForQt5.qtstyleplugins
      libsForQt5.qt5.qtwayland

      xdg-user-dirs

      acpi
      fastfetch
      libva-utils
      pciutils

      docker-compose
      wayland
      vim
      libnotify
      unzip
      zip
      wget
      stow
      killall
      gnumake
      glxinfo
      openssl

      brightnessctl
      python3
      gcc
      cargo
      ripgrep
      pavucontrol
      mpv

      noto-fonts
      (callPackage ../../configs/sddm-catppuccin.nix {}).catppuccin-flavour
    ];
    pathsToLink = ["/libexec"];
    localBinInPath = true;
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerdfonts
    ];
  };
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/11
    i2c.enable = true;
  };
  networking = {
    hostName = "nixos";
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    firewall = {
      enable = true;
      allowedTCPPorts = [80 443 4200 3000];
      allowedUDPPortRanges = [
        {
          from = 4000;
          to = 4007;
        }
        {
          from = 8000;
          to = 8010;
        }
      ];
    };
  };
  i18n.defaultLocale = "en_US.UTF-8";
  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    overlays = [
      (self: super: {
        mpv = super.mpv.override {
          scripts = [self.mpvScripts.mpris];
        };
      })
    ];
  };
  programs = {
    nix-ld.enable = true;
    mtr.enable = true;
    neovim = {
      # viAlias = true;
      # vimAlias = true;
      enable = true;
      defaultEditor = true;
    };
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };
  sound.enable = true;
  services = {
    # File mounting
    tumbler.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;

    flatpak.enable = true;
    blueman.enable = true;
    openssh.enable = true;
    dbus = {
      enable = true;
      packages = with pkgs; [blueman];
    };
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
    };
  };
  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channel/nixos-unstable";
    };
    stateVersion = "23.05";
  };
  time.timeZone = "Africa/Johannesburg";
  users.users.francois = {
    isNormalUser = true;
    description = "Francois";
    extraGroups = ["networkmanager" "wheel" "video" "audio" "lp" "scanner" "storage"];
    shell = pkgs.fish;
  };
  xdg = {
    portal = {
      enable = true;
    };
    mime = {
      enable = true;
      defaultApplications = {};
    };
  };
}
