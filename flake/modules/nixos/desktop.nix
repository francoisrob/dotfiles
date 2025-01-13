{ pkgs, ... }:
{
  programs = {
    uwsm.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  services = {
    xserver = {
      enable = true;
      excludePackages = with pkgs; [
        xterm
      ];
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
        };
      };
      desktopManager = {
        gnome = {
          enable = true;
        };
      };
    };
    gnome.gnome-keyring.enable = true;
    libinput = {
      enable = true;
    };
    # greetd = {
    #   enable = true;
    #   settings = {
    #     initial_session = {
    #       command = "${pkgs.hyprland}/bin/Hyprland";
    #     };
    #   };
    #   # settings = rec {
    #   #   initial_session = {
    #   #     command = "${pkgs.hyprland}/bin/Hyprland";
    #   #     user = "francois";
    #   #   };
    #   #   default_session = initial_session;
    #   # };
    # };
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

  # environment.etc."greetd/environments".text = ''
  #   Hyprland
  #   gdm3
  #   fish
  #   bash
  # '';
}
