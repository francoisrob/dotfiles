{
  lib,
  pkgs,
  inputs,
  hostName,
  tuning,
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
    kernelModules = [
      "tcp_bbr"
    ];

    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      systemd = {
        enable = true;
      };
    };

    kernel = {
      sysctl = {
        "vm.swappiness" = 100;
        "vm.watermark_boost_factor" = 0;
        "vm.watermark_scale_factor" = 200;
        "vm.page-cluster" = 0;
        "vm.vfs_cache_pressure" = 50;
        "kernel.sysrq" = 1;

        "vm.dirty_background_bytes" = 64 * 1024 * 1024;
        "vm.dirty_bytes" = 256 * 1024 * 1024;

        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 87380 16777216";
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
      };
    };

    kernelParams = [
      "quiet"
      "8250.nr_uarts=0"

      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"

      "mitigations=off"
    ];

    tmp = {
      useTmpfs = true;
      tmpfsSize = "4G";
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
      nettools
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
        "commit=60"
      ];
    };
  };

  systemd = {
    settings = {
      Manager = {
        RebootWatchdogSec = "0";
      };
    };
    services.NetworkManager-wait-online.enable = lib.mkForce false;

    coredump.settings.Coredump = {
      ProcessSizeMax = "1G";
      ExternalSizeMax = "1G";
      MaxUse = "2G";
    };
  };

  powerManagement = {
    enable = true;
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
  };

  services = {
    resolved.enable = true;
    fstrim.enable = true;
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", TEST=="power/control", ATTR{power/control}="on"
    '';
    udev.packages = [pkgs.brightnessctl];

    udisks2 = {
      enable = true;
    };
    devmon = {
      enable = true;
    };

    logind = {
      settings = {
        Login = {
          KillUserProcesses = false;
          HandlePowerKey = "lock";
          HandlePowerKeyLongPress = "reboot";
        };
      };
    };

    upower = {
      enable = true;
    };
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
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
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    journald.settings.Journal = {
      Storage = "persistent";
      RateLimitBurst = 1000;
      SystemMaxUse = "1G";
      RuntimeMaxUse = "512M";
    };
  };

  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults!/run/current-system/sw/bin/true !syslog
      '';
      extraRules = [
        {
          groups = ["wheel"];
          commands = [
            {
              command = "/run/current-system/sw/bin/systemctl start mongodb";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/systemctl stop mongodb";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/systemctl start teamviewerd";
              options = ["NOPASSWD"];
            }
            {
              command = "/run/current-system/sw/bin/systemctl stop teamviewerd";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };
    polkit = {
      enable = true;
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
          KernelExperimental = "6fbaf188-05e0-496a-9885-d6ddfdb4e03e";
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
      };
    };
  };

  networking = {
    inherit hostName;
    useDHCP = false;
    resolvconf.enable = false;
    wireless = {
      iwd = {
        enable = true;
        settings = {
          General = {
            EnableNetworkConfiguration = false;
            RoamThreshold = -70;
            RoamThreshold5G = -70;
            RoamRetryInterval = 60;
          };
          Network = {
            EnableIPv6 = true;
          };
        };
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
    config = import ../nixpkgs-config.nix;
  };

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      max-jobs = tuning.maxJobs;
      auto-optimise-store = true;
      cores = tuning.buildCores;
      substituters = [
        "https://nix-community.cachix.org"
        "https://neovim-nightly.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "neovim-nightly.cachix.org-1:feIoInHRevVEplgdZvQDjhp11kYASYCE2NGY9hNrwxY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];

      experimental-features = ["nix-command" "flakes"];
      download-buffer-size = 524288000;

      build-dir = "/nix/var/nix/builds";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "45min";
      options = "--delete-older-than 14d";
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  system = {
    stateVersion = "26.05";
  };

  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000"
    "d /nix/var/nix/builds 0755 root root -"
  ];

  systemd.oomd = {
    enable = true;
    enableRootSlice = false;
    enableSystemSlice = false;
    enableUserSlices = false;
    settings.OOM = {
      SwapUsedLimit = "70%";
    };
  };

  systemd.slices."-".sliceConfig.ManagedOOMSwap = "kill";

  services.earlyoom = {
    enable = true;
    freeMemThreshold = tuning.earlyoomMemThreshold;
    freeMemKillThreshold = tuning.earlyoomMemKillThreshold;
    freeSwapThreshold = 50;
    freeSwapKillThreshold = 25;
    enableNotifications = true;
    extraArgs = [
      "--avoid"
      "^(systemd|systemd-oomd|earlyoom|dbus-broker|sshd|greetd|\\.Hyprland-wrapp|\\.kitty-wrapped)$"
      "--prefer"
      "^(chromium|node|electron|\\.electron-wrappe|java|rustc|cargo|clangd|mongod)$"
    ];
  };

  zramSwap = {
    enable = true;
    memoryPercent = tuning.zramPercent;
    priority = 100;
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = tuning.swapFileSize;
      priority = 10;
    }
  ];
}
