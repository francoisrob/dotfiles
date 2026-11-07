{
  pkgs,
  inputs,
  user,
  ...
}: let
  hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in {
  specialisation = {
    legacy-hda-audio.configuration = {
      system.nixos.tags = ["legacy-hda-audio"];
      boot.kernelParams = ["snd_intel_dspcfg.dsp_driver=1"];
    };
  };

  boot = {
    initrd = {
      luks.devices."luks-42daaaa8-649b-4c1f-b76d-28a33b522eba".allowDiscards = true;
    };

    kernelParams = [
      "ucsi_ccg.skip_ucsi=1"
    ];
  };

  networking = {
    networkmanager.wifi.backend = "iwd";
    wireless.iwd = {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = false;
          RoamThreshold = -70;
          RoamThreshold5G = -70;
          RoamRetryInterval = 60;
        };
        Network.EnableIPv6 = true;
      };
    };
  };

  services = {
    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "ignore";
          HandleLidSwitchDocked = "ignore";
        };
      };
    };

    tlp = {
      enable = true;
      settings = {
        USB_EXCLUDE_BTUSB = 1;

        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        PLATFORM_PROFILE_ON_AC = "balanced";
        WIFI_PWR_ON_AC = "off";
      };
    };

    thermald = {
      enable = true;
    };
  };

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
              ${hyprland.hyprland}/bin/hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "2560x1600@60", position = "0x0", scale = 1 })'
            HYPRLAND_INSTANCE_SIGNATURE="$hs" \
              ${hyprland.hyprland}/bin/hyprctl dispatch 'hl.dsp.dpms("on", "eDP-1")'
            break
          fi
        done
      ''}";
    };
  };

  services.udev.extraRules = ''
    ACTION=="remove", SUBSYSTEM=="thunderbolt", RUN+="${pkgs.systemd}/bin/systemctl start --no-block undock-wake-display.service"
  '';
}
