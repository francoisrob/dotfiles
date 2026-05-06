{...}: {
  hardware.bluetooth = {
    enable = true;
    settings = {
      Policy = {
        # Back off quickly when device is off/out of range; auto-connect
        # still triggers when the device advertises itself.
        ReconnectAttempts = 3;
        ReconnectIntervals = "1, 2, 4";
      };
    };
  };

  # Suppress reconnect noise from bluetoothd at warning level and below
  systemd.services.bluetooth.serviceConfig.LogLevelMax = "err";
}
