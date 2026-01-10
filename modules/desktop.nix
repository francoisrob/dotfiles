{
  pkgs,
  inputs,
  user,
  ...
}: let
  hyprland-contrib = inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system};
  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
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

  nixpkgs.overlays = [
    (final: prev: {
      waybar_git = prev.waybar.overrideAttrs (oldAttrs: {
        src = inputs.waybar;
      });
    })
  ];

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
    seahorse = {
      enable = true;
    };
  };

  services = {
    # teamviewer.enable = true;

    libinput = {
      enable = true;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "uwsm start -N Hyprland hyprland-uwsm.desktop >> /dev/null";
          # command = "${pkgs.uwsm}/bin/uwsm start -N Hyprland";
          # command = "${tuigreet} -r -t --asterisks --cmd 'uwsm start -N Hyprland hyprland-uwsm.desktop >> /dev/null'";
          user = user;
        };
      };
    };
  };

  security = {
    pam = {
      services.greetd = {
        enableGnomeKeyring = true;
      };
    };
  };

  xdg = {
    mime = {
      enable = true;
    };
    portal = {
      enable = true;
      wlr = {
        enable = true;
      };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config = {
        common = {
          default = [ "hyprland" "gtk" ];
        };
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      # libsecret
      # hyprpolkitagent

      wayland # Needed for Hyprland
      libnotify # Needed for notifications
      rofi

      hyprland-contrib.grimblast
      hyprland-contrib.shellevents

      hyprwayland-scanner
      hyprlock
    ];
  };
}
