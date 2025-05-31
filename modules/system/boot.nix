{
  pkgs,
  inputs,
  hostName,
  ...
}: {
  boot = {
    kernelPackages = pkgs.linuxPackages;
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
        "vm.swappiness" = 1;
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
      glxinfo
      openssl
      brightnessctl
      pavucontrol
      inotify-tools
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
        "discard"
      ];
    };
    "/home" = {
      options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };
    "/tmp" = {
      options = [
        "noatime"
        "nodiratime"
        "discard"
      ];
    };
  };

  systemd = {
    watchdog = {
      rebootTime = "0";
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
    # envfs.enable = true;

    # File mounting
    udisks2 = {
      enable = true;
    };
    devmon = {
      enable = true;
    };

    logind = {
      killUserProcesses = true;
      powerKey = "lock";
      powerKeyLongPress = "reboot";
      lidSwitch = "lock";
      lidSwitchExternalPower = "ignore";
      lidSwitchDocked = "ignore";
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

    blueman = {
      enable = true;
    };

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
      allowedTCPPorts = [3000];
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

  zramSwap = {
    enable = true;
    memoryPercent = 40;
  };
}
