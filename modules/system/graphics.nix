{pkgs, ...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl

        mesa
        vulkan-tools
      ];
    };
  };
}
