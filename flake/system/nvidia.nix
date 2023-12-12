{
  config,
  pkgs,
  ...
}: {
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    # "module_blacklist=i915"
  ];

  # boot.extraModulePackages = [config.boot.kernelPackages.nvidia_x11];

  hardware = {
    nvidia = {
      modesetting.enable = true;

      powerManagement.enable = true;

      powerManagement.finegrained = false;

      open = false;
      
      nvidiaSettings = true;
      
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      
      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";

        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        # reverseSync.enable = true;
      };
    };

    opengl.extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  services.xserver.videoDrivers = ["nvidia"];
}
