{pkgs, ...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl

        mesa
        mesa.drivers
        vulkan-tools
      ];
    };
  };
}
