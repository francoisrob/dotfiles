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

    # Disable Intel WiFi firmware power management (CAM / "active"). power_scheme
    # is read-only at runtime, so this can't be made AC-conditional — it applies
    # on battery too. Lowers WiFi latency/jitter and steadies 2.4GHz Wi-Fi/BT
    # coexistence (AX201 shares one radio), at some idle-battery cost on DC.
    extraModprobeConfig = ''
      options iwlmvm power_scheme=1
    '';

    consoleLogLevel = 0;

    initrd = {
      verbose = false;
      systemd = {
        enable = true;
      };
      # Without this the dm-crypt mapper advertises no discard support
      # (DISC-GRAN 0B), so TRIM never reaches the SSD, neither via a discard
      # mount option nor via fstrim.
      luks.devices."luks-42daaaa8-649b-4c1f-b76d-28a33b522eba".allowDiscards = true;
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

        # Cap the dirty-page writeback backlog by BYTES, not ratio. The old
        # config set dirty_ratio=10 and left dirty_background_ratio at its
        # default of 10 too -- equal thresholds mean there is no gentle
        # background-drain window: the kernel jumps straight to the hard
        # synchronous stall at dirty_ratio, where ALL writers block until the
        # backlog drains. On 16G RAM, 10% is ~1.6G of dirty pages, so a single
        # bulk writer (a browser download, a build artifact) could build that
        # backlog and freeze every other writer system-wide -- the recurring
        # I/O-pressure freeze (PSI io full was ~70%). *_bytes and *_ratio are
        # mutually exclusive (writing *_bytes zeroes the matching *_ratio):
        # start background writeback at 64M, hard-throttle at 256M -- small
        # enough the NVMe clears it in well under a second, so the throttle
        # point is a brief hiccup instead of a multi-second whole-system stall.
        "vm.dirty_background_bytes" = 64 * 1024 * 1024;
        "vm.dirty_bytes" = 256 * 1024 * 1024;

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

      # Intentional: disable all CPU speculative-execution mitigations to reclaim
      # throughput on this thermally-limited i7-1165G7. This is a deliberate
      # perf-over-security trade-off (Spectre/MDS/L1TF/Downfall/etc. left
      # unmitigated); revert to the kernel default with "mitigations=auto" if
      # the threat model changes.
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
      # TRIM is handled by the weekly fstrim timer below, not a continuous
      # discard mount option (per-delete discards add write latency on NVMe).
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
    # This host uses NetworkManager, so the networkd variant is inert; disable
    # the NetworkManager wait-online unit that actually gates boot here.
    services.NetworkManager-wait-online.enable = lib.mkForce false;

    # Cap core dumps so a crashing multi-GB process (bun/chromium/electron/node)
    # can't flood the LUKS disk and freeze the machine. A bun SIGILL crash-loop
    # once produced ~10-12G dumps that saturated the ext4 journal (I/O pressure
    # 86%, load 9 on 8 cores). Over ProcessSizeMax the dump is skipped, but
    # systemd-coredump still logs the crashing exe+cmdline to the journal, so the
    # trigger stays identifiable without writing the giant core.
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
    # Weekly TRIM of the LUKS-backed root; needs allowDiscards on the mapper above.
    fstrim.enable = true;
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

        # Balanced on AC, deliberately NOT full 'performance': this i7-1165G7 is
        # thermally limited (PL1 unbounded, ~83C at light load, frequent package
        # throttling), so pinning max clocks only raised idle temps without a
        # sustained-throughput gain. balance_performance lets HWP/turbo ramp
        # under load without sitting at Tjmax.
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        PLATFORM_PROFILE_ON_AC = "balanced";
        # Keep WiFi radio fully awake on AC (explicit; matches TLP default).
        WIFI_PWR_ON_AC = "off";
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
    config = import ../nixpkgs-config.nix;
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
