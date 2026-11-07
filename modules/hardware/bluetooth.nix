{...}: {
  hardware.bluetooth = {
    enable = true;
    settings = {
      Policy = {
        ReconnectAttempts = 3;
        ReconnectIntervals = "1, 2, 4";
      };
    };
  };

  systemd.services.bluetooth.serviceConfig.LogLevelMax = "err";
}
