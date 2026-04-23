{
  config,
  pkgs,
  ...
}: let
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.legacy_580;
in {
  boot = {
    kernelModules = [
      "nvidia_uvm"
    ];
    kernelParams = [

      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
  };

  hardware = {
    nvidia = {
      open = false;
      nvidiaSettings = true;
      package = nvidiaPackage;
      modesetting = {
        enable = true;
      };

      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
      };
    };

    graphics = {
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
      ];
    };
  };

  services = {
    xserver = {
      videoDrivers = ["nvidia"];
    };
  };
}
