{
  pkgs,
  inputs,
  hostName,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
      };
      efi = {
        canTouchEfiVariables = true;
      };
    };
    supportedFilesystems = ["ntfs"];

    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      systemd = {
        enable = true;
        services = {
          "*" = {
            serviceConfig = {
              DefaultDependencies = false;
            };
          };
        };
      };
    };

    kernel = {
      sysctl = {
        "vm.swappiness" = 100;
        # "kernel.sched_migration_cost_ns" = 500000;
        # "vm.dirty_background_ratio" = 5;
        "vm.dirty_ratio" = 10;
        "vm.nr_hugepages" = 128;
        "vm.transparent_hugepages" = "always";
        # "vm.transparent_hugepages" = "madvise";

        # network optimizations
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        # "net.core.netdev_max_backlog" = 5000;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 87380 16777216";
        # "net.ipv4.tcp_mtu_probing" = 1;
      };
    };

    kernelParams = [
      "quiet"
      "8250.nr_uarts=0"

      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"

      "mitigations=off"

      "sysrq_always_enabled=1"
      "rcu_nocbs=0-7"
      "pcie_aspm=force"
      "nvme.noacpi=1"
      "usbcore.autosuspend=-1"

      # "acpi_osi=" # breaks touchpad multitouch gestures
      # "acpi_backlight=vendor"

      "ucsi_acpi.trace=0"
      "ucsi_ccg.skip_ucsi=1"
      # "i2c_hid.ignore_special_reports=1"
    ];

    tmp = {
      useTmpfs = true;
      tmpfsSize = "20%";
    };
  };

  environment = {
    etc = {
      "issue" = {
        text = "";
      };
    };
    systemPackages = with pkgs; [
      ntfs3g
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
      mesa-demos
      openssl
      brightnessctl
      pavucontrol
      inotify-tools
      playerctl
    ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";
    };
    pathsToLink = ["/libexec"];
    localBinInPath = true;
  };

  fileSystems = {
    "/" = {
      options = [
        "noatime"
        "nodiratime"
        "commit=120"
        "data=ordered"
        "discard"
      ];
    };
  };

  systemd = {
    settings = {
      Manager = {
        RebootWatchdogSec = "0";
      };
    };
    services = {
      NetworkManager-wait-online = {
        enable = false;
      };
    };
  };

  powerManagement = {
    enable = true;
    powertop = {
      enable = true;
    };
  };

  programs = {
    nix-ld = {
      enable = true;
    };
    mtr = {
      enable = true;
    };
    fish = {
      enable = true;
      useBabelfish = true;
      vendor = {
        config = {
          enable = false;
        };
        completions = {
          enable = false;
        };
        functions = {
          enable = false;
        };
      };
    };
    gnupg = {
      agent = {
        enable = true;
        enableSSHSupport = true;
      };
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
    # Disable autosuspend for Bluetooth USB controller
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", TEST=="power/control", ATTR{power/control}="on"
    '';

    # envfs.enable = true;

    # File mounting
    udisks2 = {
      enable = true;
    };
    devmon = {
      enable = true;
    };

    logind = {
      settings = {
        Login = {
          KillUserProcesses = true;
          HandlePowerKey = "lock";
          HandlePowerKeyLongPress = "reboot";
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };
      };
    };

    # Power
    upower = {
      enable = true;
    };
    tlp = {
      enable = true;
    };
    thermald = {
      enable = true;
    };
    system76-scheduler = {
      settings = {
        cfsProfiles = {
          enable = true;
        };
      };
    };

    dbus = {
      enable = true;
      implementation = "broker";
    };

    # blueman = {
    #   enable = true;
    # };

    openssh = {
      enable = true;
    };

    journald = {
      storage = "volatile";
      rateLimitBurst = 1000;
      extraConfig = "RuntimeMaxUse=512M";
    };
  };

  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults!/run/current-system/sw/bin/true !syslog
      '';
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

  time = {
    timeZone = "Africa/Johannesburg";
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
          JustWorksRepairing = "always";
          ControllerMode = "dual";
        };
      };
    };
    i2c = {
      enable = true;
    };
    logitech = {
      wireless = {
        enable = true;
        enableGraphical = true;
      };
    };
  };

  networking = {
    inherit hostName;
    wireless = {
      iwd = {
        enable = true;
      };
    };
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
      };
    };
    firewall = {
      enable = true;
    };

    nftables = {
      enable = true;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      max-jobs = "auto";
      # hard link duplicates
      auto-optimise-store = true;
      cores = 0;
      substituters = [
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];

      experimental-features = ["nix-command" "flakes"];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "45min";
      options = "--delete-older-than 2d";
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  system = {
    stateVersion = "24.05";
  };

  systemd.oomd = {
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
    settings.OOM = {
      DefaultMemoryPressureLimit = "60%";
      DefaultMemoryPressureDurationSec = "20s";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 35;
  };
}
