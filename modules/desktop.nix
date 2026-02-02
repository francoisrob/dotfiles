{
  pkgs,
  inputs,
  user,
  ...
}: let
  hyprland-contrib = inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system};
  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  tuigreet = "${pkgs.tuigreet}/bin/tuigreet";
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
    seahorse = {
      enable = true;
    };
  };

  services = {
    gnome.gnome-keyring.enable = true;
    # teamviewer.enable = true;
    libinput = {
      enable = true;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${tuigreet} --time --remember --user-menu --asterisks --theme 'border=blue;text=white;prompt=magenta;time=cyan;action=yellow;button=green;container=black' --cmd '${pkgs.bash}/bin/bash -lc \"uwsm start -N Hyprland hyprland-uwsm.desktop >/dev/null 2>&1\"'";
          user = "greeter";
        };
      };
    };
  };

  security = {
    pam.services.greetd.enableGnomeKeyring = true;
  };

  console = {
    font = "Goha-16";
    packages = [pkgs.kbd];
    colors = [
      "11111b"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "bac2de"
      "181825"
      "f38ba8"
      "a6e3a1"
      "f9e2af"
      "89b4fa"
      "f5c2e7"
      "94e2d5"
      "cdd6f4"
    ];
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
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      config = {
        common = {
          default = ["hyprland" "gtk"];
        };
      };
    };
  };

  environment = {
    sessionVariables = {
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    };
    systemPackages = with pkgs; [
      wayland # Needed for Hyprland
      libnotify # Needed for notifications
      rofi

      # ashell
      waytrogen

      hyprland-contrib.grimblast
      hyprland-contrib.shellevents

      hyprwayland-scanner
      hyprlauncher
      hyprlock

      iwgtk
      blueman
    ];
  };
}
