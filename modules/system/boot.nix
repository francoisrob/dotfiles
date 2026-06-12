{
  lib,
  pkgs,
  inputs,
  hostName,
  ...
}: {
  specialisation = {
    legacy-hda-audio.configuration = {
      system.nixos.tags = ["legacy-hda-audio"];
      # Fallback profile for SOF regressions on Intel laptops. This prefers the
      # legacy HDA driver and may restore playback at the cost of DSP/DMIC
      # features on some machines.
      boot.kernelParams = ["snd_intel_dspcfg.dsp_driver=1"];
    };
  };

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
        # Bias toward zram (priority 32767) but allow disk swapfile (priority 10)
        # as a backstop. 100 keeps anon pages resident longer than the
        # zram-only 180 so node test heaps don't immediately spill to SSD.
        "vm.swappiness" = 100;
        # Disable watermark boost: it causes thrashing spikes with zram
        "vm.watermark_boost_factor" = 0;
        # Wake kswapd earlier so reclaim doesn't spike under sudden demand
        "vm.watermark_scale_factor" = 200;
        # No swap readahead — zram is random-access, clusters waste CPU
        "vm.page-cluster" = 0;
        # Keep inode/dentry cache longer to avoid re-reads after free
        "vm.vfs_cache_pressure" = 50;
        # Enable magic SysRq (kernel param sysrq_always_enabled=1 is not a real flag)
        "kernel.sysrq" = 1;
        # "kernel.sched_migration_cost_ns" = 500000;
        # "vm.dirty_background_ratio" = 5;
        "vm.dirty_ratio" = 10;

        # network optimizations
        "net.core.rmem_max" = 16777216;
        "net.core.wmem_max" = 16777216;
        # "net.core.netdev_max_backlog" = 5000;
        "net.ipv4.tcp_rmem" = "4096 87380 16777216";
        "net.ipv4.tcp_wmem" = "4096 87380 16777216";
        # "net.ipv4.tcp_mtu_probing" = 1;
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

      # The kernel explicitly warns that forcing ASPM can cause lockups. Keep
      # the default PCIe policy on this Tiger Lake + Thunderbolt setup because
      # the dock/monitor path is already showing D3cold/D0 resume failures.

      # "acpi_osi=" # breaks touchpad multitouch gestures
      # "acpi_backlight=vendor"


      "ucsi_ccg.skip_ucsi=1"
      # "i2c_hid.ignore_special_reports=1"
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
    services.systemd-networkd-wait-online.enable = lib.mkForce false;
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
      settings = {
        # Don't autosuspend the Intel AX201 Bluetooth controller. TLP's default
        # (USB_EXCLUDE_BTUSB=0) powers it down after 2s idle, which causes the
        # controller to fail resume mid-stream — A2DP dropouts and "firmware
        # bug / missing completion reports" glitches on the WH-1000XM6. This
        # also lets the power/control=on udev rule below actually stick.
        USB_EXCLUDE_BTUSB = 1;
      };
    };
    thermald = {
      enable = true;
    };
    system76-scheduler = {
      enable = true;
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
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };

    journald = {
      storage = "persistent";
      rateLimitBurst = 1000;
      extraConfig = ''
        SystemMaxUse=1G
        RuntimeMaxUse=512M
      '';
    };
  };

  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults!/run/current-system/sw/bin/true !syslog
      '';
      extraRules = [{
        groups = [ "wheel" ];
        commands = [
          { command = "/run/current-system/sw/bin/systemctl start mongodb"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl stop mongodb"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl start teamviewerd"; options = [ "NOPASSWD" ]; }
          { command = "/run/current-system/sw/bin/systemctl stop teamviewerd"; options = [ "NOPASSWD" ]; }
        ];
      }];
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
      # To auto-connect to devices, you need to trust them. You can do this
      # using `bluetoothctl` or a TUI/GUI bluetooth manager. For example:
      #   $ bluetoothctl
      #   [bluetooth]# devices
      #   [bluetooth]# trust <device_mac_address>
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
        enableGraphical = true;
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
            EnableNetworkConfiguration = false; # NetworkManager handles IP configuration
            RoamThreshold = -75;
            RoamThreshold5G = -80;
            RoamRetryInterval = 120;
          };
          Network = {
            EnableIPv6 = true;
          };
          Scan = {
            DisablePeriodicScan = true;
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
    config = {
      allowUnfree = true;
      # Electron 39 is EOL upstream but still pulled in by Electron-based
      # desktop apps (slack, discord, mongodb-compass, etc.). Allow it until
      # those packages bump to a supported Electron. Re-checked 2026-06-13:
      # still required on nixos-unstable.
      permittedInsecurePackages = [
        "electron-39.8.10"
      ];
    };
  };

  nix = {
    # Build at low priority so nixos-rebuild can't freeze the desktop: SCHED_IDLE
    # means interactive tasks preempt builds instantly, and idle I/O class yields
    # the disk to foreground work.
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      # 4 jobs x 2 cores = 8 threads max on this 4c/8t machine. Was max-jobs=auto
      # (8) x cores=0 (all 8) which oversubscribed to ~64 build threads and spiked
      # load past 15, starving the desktop.
      max-jobs = 4;
      # hard link duplicates
      auto-optimise-store = true;
      cores = 2;
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
  ];

  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
    settings.OOM = {
      # Kill cgroups before swap is exhausted, not after
      SwapUsedLimit = "80%";
      DefaultMemoryPressureLimit = "55%";
      DefaultMemoryPressureDurationSec = "10s";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    # Must outrank the disk swapfile (priority 10) so anon pages compress into
    # RAM first and the SSD is only a backstop. Without this, zramSwap defaults
    # to priority 5 and the kernel pages to the slow swapfile first, causing
    # I/O-thrash freezes under memory pressure.
    priority = 100;
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 8 * 1024;
    priority = 10;
  }];
}
