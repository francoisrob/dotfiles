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
  #
  # ddcutil drives external monitors over DDC/CI (brightness, contrast, input
  # source) via VCP feature codes on the I2C bus. It is what the wayle bar's
  # brightness module calls, since brightnessctl only knows about internal
  # laptop panel backlights. hardware.i2c.enable in modules/system/boot.nix
  # already loads i2c-dev and grants the `video` group access, so this needs no
  # extra permissions. Shared rather than host-scoped because .config/wayle is
  # shared, so the bar would break on any host missing the binary.
  environment.systemPackages = with pkgs; [
    vulkan-tools
    ddcutil
  ];
}
