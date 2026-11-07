{tuning, ...}: {
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 200;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_background_bytes" = 64 * 1024 * 1024;
    "vm.dirty_bytes" = 256 * 1024 * 1024;
  };

  systemd = {
    coredump.settings.Coredump = {
      ProcessSizeMax = "1G";
      ExternalSizeMax = "1G";
      MaxUse = "2G";
    };
    tmpfiles.rules = ["w /sys/kernel/mm/lru_gen/min_ttl_ms - - - - 1000"];
    oomd = {
      enable = true;
      enableRootSlice = false;
      enableSystemSlice = false;
      enableUserSlices = false;
      settings.OOM.SwapUsedLimit = "70%";
    };
    slices."-".sliceConfig.ManagedOOMSwap = "kill";
  };

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
