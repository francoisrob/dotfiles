{
  imports = [
    ./hardware-configuration.nix

    ../../modules/hardware/cpu/intel.nix
    ../../modules/hardware/gpu/nvidia.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix

    ../../modules/programs/steam.nix
    ../../modules/programs/gaming.nix
    ../../modules/programs/thunar.nix

    ../../modules/system/boot.nix
    ../../modules/system/laptop.nix
    ../../modules/system/fonts.nix
    ../../modules/system/graphics.nix
    ../../modules/system/networking.nix

    ../../modules/virtualisation/default.nix
    ../../modules/virtualisation/docker.nix

    ../../modules/desktop.nix

    ../../modules/development

    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/user.nix
  ];
}
