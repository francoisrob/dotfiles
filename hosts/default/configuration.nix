{
  imports = [
    ./hardware-configuration.nix

    # Hardware
    ../../modules/hardware/cpu/intel.nix
    ../../modules/hardware/gpu/nvidia.nix
    ../../modules/hardware/audio.nix

    # Programs
    ../../modules/programs/steam.nix
    ../../modules/programs/thunar.nix

    # System
    ../../modules/system/boot.nix
    ../../modules/system/fonts.nix
    ../../modules/system/graphics.nix

    # Virtualization
    ../../modules/virtualisation/default.nix
    ../../modules/virtualisation/docker.nix

    # Desktop
    ../../modules/desktop.nix

    # Development
    ../../modules/development

    # TODO: REFACTOR
    ../../modules/home.nix
    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/user.nix

    # ../../modules/home.nix
    # ../../modules/packages.nix
    # ../../modules/services.nix
    # ../../modules/user.nix
  ];
}
