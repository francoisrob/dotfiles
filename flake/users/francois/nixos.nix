{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 5;
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["ntfs"];

    # PLYMOUTH
    consoleLogLevel = 0;
    initrd.verbose = false;
    plymouth.enable = true;
    kernelParams = [ 
      "quiet"
      "splash" 
      "rd.systemd.show_status=false" 
      "rd.udev.log_level=3" 
      "udev.log_priority=3" 
      "boot.shell_on_fail" 
    ];
  };
  console = {
    colors = [
      "1b1b1b"
      "0e363e"
      "34381b"
      "374141"
      "402120"
      "4c3432"
      "4f422e"
      "504945"
      "7daea3"
      "a9b665"
      "89b482"
      "ea6962"
      "d3869b"
      "d8a657"
      "a89984"
      "ddc7a1"
    ];
    keyMap = "us";
    enable = true;
    earlySetup = true;
    packages = with pkgs; [ terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
  };
  environment = {
    systemPackages = with pkgs; [
      xdg-user-dirs

      acpi
      fastfetch
      libva-utils
      pciutils

      wayland # Needed for Hyprland
      libnotify # Needed for dunst
      unzip # Needed for unzip
      gnome.file-roller # Needed for zip

      btop

      wget
      stow
      killall

      kitty

      glxinfo
      openssl
      brightnessctl
      pavucontrol
      mpv

      # Developer
      gnumake
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
    nameservers = ["8.8.8.8"];
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
    nix-ld.enable = true;
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
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin 
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
  };
  security = {
    sudo = {
      enable = true;
    };
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
      alsa = {
          enable = true;
          support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
      jack.enable = true;
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
      channel = "https://nixos.org/channel/nixos-unstable";
    };
    stateVersion = "23.05";
  };

  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.francois = {
    isNormalUser = true;
    description = "Francois Robbertze";
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
