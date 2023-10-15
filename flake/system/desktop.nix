{
  inputs,
  pkgs,
  ...
}: {
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
      enableNvidiaPatches = false;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };
  };
  services = {
    xserver = {
      enable = true;
      displayManager = {
        sddm = {
          enable = true;
          wayland.enable = true;
          theme = "catppuccin-mocha";
        };
      };
    };
  };
}
