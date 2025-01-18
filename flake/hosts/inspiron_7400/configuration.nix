{ pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/virtualization.nix
    ../../modules/nixos/hardware-acceleration.nix
    ../../modules/nixos/steam.nix
    ../../modules/nixos/nvidia.nix

    ../../modules/nixos/thunar.nix
    ../../modules/nixos/fonts.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 5;
      systemd-boot = {
        enable = true;
      };
      efi.canTouchEfiVariables = true;
    };
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
    };
    plymouth.enable = true;
    kernelParams = [
      "quiet"
      "loglevel=3"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"

      # high res
      "video=2560x1200"
      "fbcon=font:TER16x32"

      "i915.enable_psr=1"
      "i915.fastboot=1"
      "i915.enable_guc=3"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      xdg-user-dirs

      acpi
      fastfetch
      libva-utils
      pciutils

      unzip # Needed for unzip

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
      tmux
      fd
      fzf
      gnumake
      ripgrep
      mongosh
      mongodb-tools

      lua
      luajitPackages.luarocks
      go
      python3
      gcc
      cargo
      nil
      nixfmt-rfc-style
    ];
    pathsToLink = [ "/libexec" ];
    localBinInPath = true;
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    i2c.enable = true;
  };

  networking = {
    hostName = "nixos";
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit pkgs;
      inherit inputs;
    };
    users.francois = {
      imports = [
        ./home.nix
      ];
    };
  };

  powerManagement.powertop.enable = true;
  programs = {
    nix-ld.enable = true;
    mtr.enable = true;
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  security = {
    sudo.enable = true;
    polkit.enable = true;
    acme = {
      acceptTerms = true;
      defaults.email = "francoisdprob@gmail.com";
    };
  };

  services = {
    envfs.enable = true;
    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
    };
    # File mounting
    udisks2.enable = true;
    devmon.enable = true;

    flatpak.enable = true;
    blueman.enable = true;
    openssh.enable = true;

    # Power
    upower.enable = true;
    thermald.enable = true;
    system76-scheduler.settings.cfsProfiles.enable = true;

    dbus = {
      enable = true;
      packages = with pkgs; [ blueman ];
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      allowReboot = true;
      channel = "https://nixos.org/channel/nixos-unstable";
    };
    stateVersion = "24.05";
  };

  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.francois = {
    isNormalUser = true;
    description = "Francois Robbertze";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "lp"
      "scanner"
      "storage"
    ];
    shell = pkgs.fish;
  };

}
