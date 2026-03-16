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
      # plugins = [
      #   inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
      #   inputs.hypr-dynamic-cursors.packages.${pkgs.stdenv.hostPlatform.system}.hypr-dynamic-cursors
      # ];
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
    teamviewer.enable = true;
    libinput = {
      enable = true;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${tuigreet} --time --remember --user-menu --asterisks --theme 'border=blue;text=white;prompt=magenta;time=cyan;action=yellow;button=green;container=black' --cmd 'uwsm start -N Hyprland hyprland-uwsm.desktop >/dev/null 2>&1'";
          user = "greeter";
        };
      };
    };
  };

  security = {
    pam.services.greetd.enableGnomeKeyring = true;
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
      SSH_AUTH_SOCK = "\${XDG_RUNTIME_DIR}/keyring/ssh";
    };
    systemPackages = with pkgs; [
      wayland # Needed for Hyprland
      libnotify # Needed for notifications

      # ashell
      waytrogen

      hyprland-contrib.grimblast
      hyprland-contrib.shellevents

      hyprwayland-scanner
      hyprlauncher
      hyprlock
      hyprsunset

      iwgtk
      blueman
    ];
  };
}
