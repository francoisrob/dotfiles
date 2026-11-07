{...}: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
        KernelExperimental = "6fbaf188-05e0-496a-9885-d6ddfdb4e03e";
        JustWorksRepairing = "always";
        ControllerMode = "dual";
      };
      Policy = {
        ReconnectAttempts = 3;
        ReconnectIntervals = "1, 2, 4";
      };
    };
  };

  services = {
    blueman.enable = true;
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="8087", TEST=="power/control", ATTR{power/control}="on"
    '';
  };

  systemd.services.bluetooth.serviceConfig.LogLevelMax = "err";
}
