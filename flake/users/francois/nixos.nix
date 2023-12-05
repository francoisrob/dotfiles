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
      # qt5ct
      # libsForQt5.qtstyleplugins
      # libsForQt5.qt5.qtwayland

      xdg-user-dirs

      acpi
      fastfetch
      libva-utils
      pciutils

      wayland
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
      pavucontrol
      mpv

      # Developer
      python3
      gcc
      cargo
      ripgrep

      noto-fonts
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

  powerManagement.powertop.enable = true;
  programs = {
    mtr.enable = true;
    neovim = {
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
    acme = {
      acceptTerms = true;
      defaults.email = "francoisdprob@gmail.com";
    };
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
    
    # Power
    upower.enable = true;
    thermald.enable = true;
    system76-scheduler.settings.cfsProfiles.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      };
    };

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
