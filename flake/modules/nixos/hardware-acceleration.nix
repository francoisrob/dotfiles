{ pkgs, ... }: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # Vulkan
      intel-compute-runtime

      # VA-API
      intel-media-driver
      # vaapiIntel # Older i965 driver

      # vaapiVdpau
      # libvdpau-va-gl
    ];
  };
}
