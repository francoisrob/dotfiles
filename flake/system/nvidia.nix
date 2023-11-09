{
  config,
  lib,
  pkgs,
  ...
}: {
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    # "module_blacklist=i915"
  ];
  boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];

  hardware = {
    nvidia = {
      modesetting.enable = true;

      powerManagement.enable = true;
      # powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;

      # package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = {
        # sync.enable = true;
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        reverseSync.enable = true;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    opengl.extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  services.xserver.videoDrivers = ["nvidia"];

  programs.hyprland.enableNvidiaPatches = true;

  specialisation = {
    on-the-go.configuration = {
      system.nixos.tags = ["on-the-go"];
      hardware.nvidia = {
        prime.offload.enable = lib.mkForce true;
        prime.offload.enableOffloadCmd = lib.mkForce true;
        prime.sync.enable = lib.mkForce false;
      };
    };
    external-display.configuration = {
      system.nixos.tags = ["external-display"];
      hardware.nvidia = {
        prime.offload.enable = lib.mkForce false;
        powerManagement.enable = lib.mkForce false;
      };
    };
  };
}
