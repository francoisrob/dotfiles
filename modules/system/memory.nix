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
    # earlyoom is the only memory killer. systemd-oomd kills a whole service at once, so one
    # runaway test inside herdr.service took every agent pane down with it.
    oomd.enable = false;
  };

  # Kills one process at a time, picked by the kernel's badness score (which already includes each
  # unit's OOMScoreAdjust), adjusted by these lists. The lists match the process name (comm, at most
  # 15 characters) and cover system daemons and the desktop. Agents are protected by OOMScoreAdjust
  # on their units (herdr, claude-remote-control, hermes-agent), not by name.
  services.earlyoom = {
    enable = true;
    freeMemThreshold = tuning.earlyoomMemThreshold;
    freeMemKillThreshold = tuning.earlyoomMemKillThreshold;
    freeSwapThreshold = 50;
    freeSwapKillThreshold = 25;
    enableNotifications = true;
    extraArgs = [
      # Never killed: herdr keeps the agent panes, tailscale and ntfy are how the phone reaches this machine.
      "--ignore"
      "^(herdr|[.]tailscaled-wra|ntfy)$"
      # Killed last: system daemons and the desktop.
      "--avoid"
      "^(systemd|earlyoom|dbus-broker|sshd|greetd|[.]Hyprland-wrapp|[.]kitty-wrapped)$"
      "--prefer"
      "^(chromium|node|electron|[.]electron-wrappe|java|rustc|cargo|clangd|mongod)$"
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
