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
      # uutils-coreutils-noprefix removed. It shadowed 105 GNU coreutils names,
      # and its `pr` balloons without bound on ordinary input: a plain 96 MiB
      # text file drove it past 4 GiB in 3.2s (>20x amplification, still
      # climbing), and `pr -W 100000000` does the same from a 13 KB file. That
      # took this machine down with two system-wide OOM kills on 2026-08-03
      # (11.08 GiB and 11.49 GiB, both with Free swap = 16kB). Separately, du,
      # stat, tsort and dirname abort on a write error when SIGPIPE is ignored.
      # There is no upgrade path: 0.9.0 is both the latest upstream release and
      # what nixpkgs ships, and the panic-on-write-error class is still being
      # found one utility at a time upstream.
      #
      # GNU coreutils-full is already in the closure, so this costs no download.
      # nettools restores `hostname`, which uutils was the only provider of;
      # `arch` is gone, use `uname -m`.
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
    # Activate brightnessctl's shipped udev rule (chgrp backlight -> video, g+w).
    # Without this the sysfs brightness file is root:root 0644, so brightnessctl
    # falls back to logind SetBrightness, which logind refuses for processes in
    # the compositor's user-manager cgroup (not the active seat session) with
    # "Invalid request descriptor" -> XF86MonBrightness keys silently do nothing.
    udev.packages = [pkgs.brightnessctl];

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
    # Auto-nice daemon: boosts foreground/interactive processes and idles out
    # background ones (the ananicy lineage this box used before). Replaces
    # system76-scheduler, whose PipeWire-monitor child crash-looped on SIGABRT
    # (nixpkgs pins a stale 2025-01 upstream snapshot). Audio realtime priority
    # is unaffected: rtkit grants it independently. Note this drops the CFS
    # latency-profile tuning system76-scheduler also did; sched_ext/scx_lavd is
    # the modern home for that half if we want it later.
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
            # "Helderspruit" is a multi-AP mesh: 3c:6a:d2:06:ca:5c and :5d plus a
            # node at 5c:62:8b:f1:25:9c that reads -18 dBm from this desk. The old
            # values (-75 / -80 / 120s) were LOOSER than iwd's defaults (-70 / -76
            # / 60s), so iwd would sit on a -73 dBm BSS at MCS 1 while a far
            # stronger one was in range, ride it down through repeated
            # "missed beacons exceeds threshold" storms, and take a local
            # reason-4 (inactivity) deauth. 45 NetworkManager activation
            # failures in four days. -70 on both bands makes it leave a bad BSS
            # while a better one exists; the 60s retry interval is what stops
            # that turning into ping-pong.
            RoamThreshold = -70;
            RoamThreshold5G = -70;
            RoamRetryInterval = 60;
          };
          Network = {
            EnableIPv6 = true;
          };
          # DisablePeriodicScan only suppresses scans while DISCONNECTED, which
          # is exactly the window that matters here: after each deauth iwd went
          # straight to autoconnect_quick off a stale BSS list and re-picked the
          # same mediocre AP instead of discovering the near one. Left at the
          # iwd default (periodic scan enabled) so a reconnect can see the mesh.
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

      # Nix builds were unpacking and compiling straight into RAM. /tmp is a 4G
      # tmpfs (boot.tmp.useTmpfs below), nix-daemon.service has PrivateTmp=no
      # and no TMPDIR in its Environment, and `nix config show` reported
      # build-dir empty, so builds fell through to /tmp. tmpfs pages are shmem:
      # they cannot be dropped, only swapped. The 2026-08-02 15:08:54 kernel OOM
      # is timestamped to the same second as system-154-link, i.e. it happened
      # during a `make switch`. build-dir is a store setting in nix.conf, so it
      # is honoured by whichever process builds, including a root nixos-rebuild
      # (TMPDIR alone has a known gap there, nixpkgs#293114).
      #
      # Nix validates EVERY ANCESTOR of build-dir for world-writability, not
      # just the leaf ("Path ... is world-writable or a symlink. That's not
      # allowed for security."). So nothing under /tmp or /var/tmp can ever
      # work, both being 1777 - a 0755 subdirectory under them still fails on
      # the parent. /nix/var/nix is drwxr-xr-x root:root the whole way up, and
      # is on the same filesystem as the store, so builds never cross devices.
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

  # KEEP THIS AT 1000. It is what fired the 2026-07-30 kill, and that was the
  # right outcome. MGLRU's min_ttl_ms tells the kernel not to evict anything
  # touched in the last N ms, and to invoke the OOM killer rather than thrash
  # when it cannot keep that promise (the balance_pgdat -> out_of_memory path in
  # lru_gen_age_node). By the time it fired, swap was 99.98% consumed (Free swap
  # = 3468kB of 16436216kB), so a kill was already unavoidable; min_ttl_ms only
  # chose a bounded ~1s kill over an unbounded freeze. Setting it to 0 buys a
  # livelock, not a rescue. Upstream flags 3000 as the risky end of the range,
  # so 1000 is already conservative.
  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000"
    # Backing directory for nix.settings.build-dir above. Every ancestor must be
    # non-world-writable too, which is why this lives under /nix/var/nix rather
    # than anywhere below /tmp or /var/tmp.
    "d /nix/var/nix/builds 0755 root root -"
  ];

  # systemd-oomd's PRESSURE path is switched off here, deliberately. It watches
  # each cgroup's PSI `full avg10`, and measurement on this box shows that
  # signal never gets anywhere near a kill threshold during the failure we
  # actually have. While a runaway fills swap the system is only ~30% stalled
  # (6.50s of stall over a 20.4s reclaim span), so avg10 asymptotes near 31 and
  # NEVER crosses 80. It is not that oomd reacts late: at this limit it cannot
  # fire at all. Pressure only spikes once swap is exhausted, which is the same
  # instant the kernel OOMs anyway.
  #
  # Two further reasons this path was never going to help:
  #   - DefaultMemoryPressureLimit was dead config. The NixOS module stamps
  #     ManagedOOMMemoryPressureLimit = mkDefault "80%" on every slice it
  #     enables, and a per-cgroup value beats the oomd.conf default, so the old
  #     "55%" here was silently ignored (oomctl reported 80.00% everywhere).
  #   - oomd kills a whole cgroup. hyprlauncher puts everything it launches in
  #     one shared scope, so a pressure kill there takes out slack, spotify and
  #     thunar together.
  #
  # The thrash case this path was meant to cover is already handled, faster, by
  # MGLRU min_ttl_ms above: that fires in ~1s where oomd needs ~28s.
  systemd.oomd = {
    enable = true;
    enableRootSlice = false;
    enableSystemSlice = false;
    enableUserSlices = false;
    settings.OOM = {
      # The one oomd rule worth keeping. Polled every 150ms
      # (SWAP_INTERVAL_USEC), and it fires only when memory-used AND swap-used
      # are both over this. 70% of 15.7G swap means zram (7.7G) is exhausted
      # and the SSD swapfile has taken over, a state idle overnight swap-out
      # never reaches.
      SwapUsedLimit = "70%";
    };
  };

  # nixpkgs sets ManagedOOMMemoryPressure but NEVER ManagedOOMSwap anywhere, so
  # `oomctl` printed "Swap Monitored CGroups:" with nothing under it and the old
  # SwapUsedLimit had zero subscribers. Both real OOMs on this machine were swap
  # exhaustion, so this was the single relevant rule and it was inert.
  systemd.slices."-".sliceConfig.ManagedOOMSwap = "kill";

  # The actual fix. earlyoom polls MemAvailable every 100ms, and MemAvailable is
  # the only leading indicator here: during a measured balloon it fell from 6473
  # to 2951 MB in THREE SECONDS while PSI read exactly 0.00 at every sample, and
  # SwapFree sat perfectly flat for 29s because the kernel evicts file cache
  # long before it touches swap.
  services.earlyoom = {
    enable = true;
    # Tune the MEMORY side and treat swap as a backstop only, which is the
    # reverse of the usual advice, because SwapFree is actively misleading on
    # this machine (see above).
    freeMemThreshold = 15;
    freeMemKillThreshold = 5;
    # earlyoom ANDs the memory and swap conditions, so the stock -s 10 would sit
    # idle until ~14G of the 15.7G of swap was consumed, i.e. the exact state
    # the machine already died in. 50% = zram exhausted, swapfile taking load.
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
