{
  config,
  pkgs,
  ...
}: {
  boot = {
    kernelModules = [
      "i915"
    ];
    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "i915.enable_guc=3"

      "intel_pstate=active"
    ];
  };
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-ocl
        intel-compute-runtime
      ];
    };
  };
}
