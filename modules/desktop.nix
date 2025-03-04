{
  pkgs,
  inputs,
  ...
}: let
  hyprland-contrib = inputs.hyprland-contrib.packages.${pkgs.system};
  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
in {
  nix = {
    settings = {
      substituters = [
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };

  programs = {
    uwsm = {
      enable = true;
    };
    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
      };
      withUWSM = true;
      package = hyprland.hyprland;
      portalPackage = hyprland.xdg-desktop-portal-hyprland;
    };
    hyprlock = {
      enable = true;
    };
  };

  services = {
    xserver = {
      enable = true;
      excludePackages = with pkgs; [
        xterm
      ];
    };

    libinput = {
      enable = true;
    };

    greetd = {
      enable = true;
      package = pkgs.stable.greetd;
      settings = {
        default_session = {
          command = "${tuigreet} -r -t --asterisks --cmd 'uwsm start -S hyprland-uwsm.desktop'";
          user = "francois";
        };
      };
    };
  };

  xdg = {
    mime.enable = true;
    portal = {
      enable = true;
      wlr = {
        enable = true;
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      libsecret
      hyprpolkitagent

      wayland # Needed for Hyprland
      libnotify # Needed for notifications
      rofi-wayland

      hyprland-contrib.grimblast
      hyprland-contrib.shellevents

      hyprwayland-scanner
      hyprlock
    ];
  };
}
