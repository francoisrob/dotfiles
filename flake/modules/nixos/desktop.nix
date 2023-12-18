{ inputs, pkgs, ... }:
{
  nix = {
    settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  services = {
    xserver = {
      enable = true;
      excludePackages = with pkgs; [
        xterm
      ];
      libinput = {
        enable = true;
      };
    };
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.hyprland}/bin/Hyprland";
          user = "francois";
        };
        default_session = initial_session;
      };
    };
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "gtk";
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };
}
