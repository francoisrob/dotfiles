{lib, ...}: {
  imports = [
    ./hardware-configuration.nix

    ../../modules/hardware/cpu/amd.nix
    ../../modules/hardware/gpu/amd.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/thunderbolt.nix

    ../../modules/programs/steam.nix
    ../../modules/programs/thunar.nix

    ../../modules/system/boot.nix
    ../../modules/system/core.nix
    ../../modules/system/nix.nix
    ../../modules/system/memory.nix
    ../../modules/system/security.nix
    ../../modules/system/fonts.nix
    ../../modules/system/graphics.nix
    ../../modules/system/networking.nix

    ../../modules/virtualisation/default.nix
    ../../modules/virtualisation/ai-containers.nix

    ../../modules/desktop.nix

    ../../modules/development

    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/user.nix

    ../../modules/webdav.nix
  ];

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  networking.networkmanager.wifi = {
    powersave = false;

    scanRandMacAddress = false;
  };

  boot.extraModprobeConfig = ''
    options iwlmvm power_scheme=1
  '';

  boot.kernelParams = ["split_lock_detect=off"];
}
