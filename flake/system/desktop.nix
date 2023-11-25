{
  inputs,
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      displayManager = {
        sddm = {
          enable = true;
          # wayland.enable = true;
          theme = "catppuccin-mocha";
          autoNumlock = true;
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    xdg-desktop-portal-gtk
  ];

  xdg = {
    portal = {
      enable = true;
      # extraPortals = with pkgs; [
        # xdg-desktop-portal-hyprland
        # xdg-desktop-portal-gtk
      # ];
    };
  };
}
