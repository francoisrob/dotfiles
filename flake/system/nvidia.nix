{
  config,
  lib,
  pkgs,
  ...
}: {
  # List GPUS ``` lspci | grep -E 'VGA|3D' ```
  # Enable OpenGL
  hardware.opengl = {
    enable = true;
    hardware.opengl.package = (import /srv/nixpkgs-mesa {}).pkgs.mesa.drivers;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  system.replaceRuntimeDependencies = [
    {
      original = pkgs.mesa;
      replacement = (import /srv/nixpkgs-mesa {}).pkgs.mesa;
    }
    {
      original = pkgs.mesa.drivers;
      replacement = (import /srv/nixpkgs-mesa {}).pkgs.mesa.drivers;
    }
  ];
}
