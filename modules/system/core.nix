{pkgs, ...}: {
  environment = {
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
  };

  fileSystems."/".options = [
    "noatime"
    "nodiratime"
    "commit=60"
  ];

  systemd.settings.Manager.RebootWatchdogSec = "0";

  powerManagement.enable = true;

  programs = {
    nix-ld.enable = true;
    mtr.enable = true;
    fish = {
      enable = true;
      useBabelfish = true;
      vendor = {
        config.enable = false;
        completions.enable = false;
        functions.enable = false;
      };
    };
  };

  services = {
    fstrim.enable = true;
    udev.packages = [pkgs.brightnessctl];
    udisks2.enable = true;
    devmon.enable = true;
    logind.settings.Login = {
      KillUserProcesses = false;
      HandlePowerKey = "lock";
      HandlePowerKeyLongPress = "reboot";
    };
    upower.enable = true;
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
    dbus = {
      enable = true;
      implementation = "broker";
    };
    journald.settings.Journal = {
      Storage = "persistent";
      RateLimitBurst = 1000;
      SystemMaxUse = "1G";
      RuntimeMaxUse = "512M";
    };
  };

  time.timeZone = "Africa/Johannesburg";

  hardware = {
    enableAllFirmware = true;
    i2c.enable = true;
    logitech.wireless.enable = true;
  };

  system.stateVersion = "26.05";
}
