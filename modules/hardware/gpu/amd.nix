{
  boot = {
    initrd = {
      kernelModules = ["amdgpu"];
    };
  };

  environment = {
    sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };
}
