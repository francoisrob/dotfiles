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

  # vulkan-tools is a CLI utility (vulkaninfo/vkcube), not a driver/ICD, so it
  # belongs here rather than in hardware.graphics.extraPackages. mesa is already
  # provided by the graphics stack by default.
  environment.systemPackages = with pkgs; [
    vulkan-tools
  ];
}
