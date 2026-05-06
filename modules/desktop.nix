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

  environment.sessionVariables = {
    TERMINAL = "kitty";
    XDG_DATA_DIRS = [];
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

  # Force eDP-1 back on after Thunderbolt undock via a fresh modesetting commit.
  # kanshi's wlr-output-management enable is insufficient when the TB hot-unplug
  # leaves the DRM CRTC in a broken state (D3cold/D0 resume failure).
  systemd.services.undock-wake-display = {
    description = "Re-enable internal display after Thunderbolt undock";
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = "${pkgs.writeShellScript "undock-wake-display" ''
        sleep 2
        for dir in /tmp/hypr/*/; do
          hs=$(basename "$dir")
          if [ -S "/tmp/hypr/$hs/.socket.sock" ]; then
            HYPRLAND_INSTANCE_SIGNATURE="$hs" \
              ${hyprland.hyprland}/bin/hyprctl keyword monitor eDP-1,2560x1600@60,0x0,1
            HYPRLAND_INSTANCE_SIGNATURE="$hs" \
              ${hyprland.hyprland}/bin/hyprctl dispatch dpms on eDP-1
            break
          fi
        done
      ''}";
    };
  };

  services.udev.extraRules = ''
    ACTION=="remove", SUBSYSTEM=="thunderbolt", RUN+="${pkgs.systemd}/bin/systemctl start --no-block undock-wake-display.service"
  '';

  xdg = {
    mime = {
      enable = true;
    };
    portal = {
      enable = true;

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

      hyprland-contrib.grimblast
      hyprland-contrib.shellevents

      hyprwayland-scanner
      hyprlauncher
      hyprlock
      hyprsunset

      papirus-icon-theme

    ];
  };
}
