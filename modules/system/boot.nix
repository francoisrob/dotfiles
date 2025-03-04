{
  pkgs,
  inputs,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 5;
      systemd-boot = {
        enable = true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["ntfs"];

    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      systemd = {
        enable = true;
      };
    };

    kernel = {
      sysctl = {
        # "kernel.sysrq" = 502;
        # "net.ipv4.tcp_syncookies" = false;
        "vm.swappiness" = 60;
      };
    };

    kernelParams = [
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"

      "mitigations=off"

      "sysrq_always_enabled=1"
      "rcu_nocbs=0-7"
      "pcie_aspm=force"
      "nvme.noacpi=1"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      xdg-user-dirs
      xdg-utils
      uutils-coreutils-noprefix
      findutils
      libva-utils
      pciutils
      acpi
      glibc
      wget
      stow
      killall
      glxinfo
      openssl
      brightnessctl
      pavucontrol
      mpv
    ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";
      C_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.glibc}/include";
      CPLUS_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.glibc}/include:${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}";
    };
    pathsToLink = ["/libexec"];
    localBinInPath = true;
  };

  systemd = {
    watchdog.rebootTime = "0";
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  programs = {
    nix-ld.enable = true;
    mtr.enable = true;
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };

  services = {
    envfs.enable = true;

    # File mounting
    udisks2.enable = true;
    devmon.enable = true;

    logind = {
      killUserProcesses = true;
      powerKey = "lock";
      powerKeyLongPress = "reboot";
      lidSwitch = "lock";
      lidSwitchExternalPower = "ignore";
      lidSwitchDocked = "ignore";
    };

    # Power
    upower.enable = true;
    thermald.enable = true;
    system76-scheduler.settings.cfsProfiles.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };

    blueman = {
      enable = true;
    };

    openssh = {
      enable = true;
    };

    journald = {
      extraConfig = "SystemMaxUse=1G";
    };
  };

  security = {
    sudo = {
      enable = true;
    };
    polkit = {
      enable = true;
    };
    acme = {
      acceptTerms = true;
      defaults = {
        email = "francoisdprob@gmail.com";
      };
    };
  };

  time.timeZone = "Africa/Johannesburg";

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

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      # hard link duplicates
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    gc = {
      automatic = true;
      dates = "daily";
      randomizedDelaySec = "10min";
    };
  };

  system = {
    stateVersion = "24.05";
  };
}
