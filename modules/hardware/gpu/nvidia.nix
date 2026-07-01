{
  config,
  pkgs,
  ...
}: let
  nvidiaPackage = config.boot.kernelPackages.nvidiaPackages.legacy_580;
in {
  # nvidia_uvm loads lazily via the driver module's upstream softdep, and
  # NVreg_PreserveVideoMemoryAllocations is already set by
  # hardware.nvidia.powerManagement.enable below — so no manual boot.* entries
  # are needed here.
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
