# GMKtec NucBox EVO-X1: Ryzen AI 9 HX 370 (Strix Point, 12c/24t) with a
# Radeon 890M iGPU and no discrete GPU. Unencrypted ext4 root, always on AC,
# no battery, no lid, no internal panel -- so none of the laptop power/display
# machinery in modules/system/laptop.nix is imported here.
{
  imports = [
    ./hardware-configuration.nix

    # Hardware
    ../../modules/hardware/cpu/amd.nix
    ../../modules/hardware/gpu/amd.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix

    # Programs
    ../../modules/programs/steam.nix
    ../../modules/programs/thunar.nix

    # System
    ../../modules/system/boot.nix
    ../../modules/system/fonts.nix
    ../../modules/system/graphics.nix
    ../../modules/system/networking.nix

    # Virtualization
    ../../modules/virtualisation/default.nix
    ../../modules/virtualisation/docker.nix

    # Desktop
    ../../modules/desktop.nix

    # Development
    ../../modules/development

    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/user.nix
  ];
}
