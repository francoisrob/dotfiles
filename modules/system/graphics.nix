{pkgs, ...}: {
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    ddcutil
  ];
}
