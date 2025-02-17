{pkgs, ...}: {
  boot = {
    initrd.kernelModules = [
      "nvidia"
      "i915"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];
    kernelParams = ["nvidia-drm.fbdev=1"];
  };
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # Vulkan
        intel-compute-runtime

        # VA-API
        intel-media-driver

        # vaapiVdpau
        # libvdpau-va-gl
        mesa.drivers
        vulkan-tools
      ];
    };
  };
}
