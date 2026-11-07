{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      alsa-utils
    ];

    sessionVariables = {
      ALSA_CONFIG_UCM2_DIR = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
    };
  };

  systemd.user = let
    ucmEnv = {
      ALSA_CONFIG_UCM2_DIR = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
    };
    realUsersOnly = {
      ConditionUser = "!@system";
    };
  in {
    services = {
      pipewire = {
        environment = ucmEnv;
        unitConfig = realUsersOnly;
      };
      wireplumber = {
        environment = ucmEnv;
        unitConfig = realUsersOnly;
      };
      pipewire-pulse = {
        environment = ucmEnv;
        unitConfig = realUsersOnly;
      };
    };
    sockets = {
      pipewire.unitConfig = realUsersOnly;
      pipewire-pulse.unitConfig = realUsersOnly;
    };
  };

  security = {
    rtkit = {
      enable = true;
    };

    pam = {
      loginLimits = [
        {
          domain = "@audio";
          item = "memlock";
          type = "-";
          value = "unlimited";
        }
        {
          domain = "@audio";
          item = "rtprio";
          type = "-";
          value = "99";
        }
        {
          domain = "@audio";
          item = "nice";
          type = "-";
          value = "-20";
        }
        {
          domain = "@audio";
          item = "nofile";
          type = "soft";
          value = "99999";
        }
        {
          domain = "@audio";
          item = "nofile";
          type = "hard";
          value = "524288";
        }
      ];
    };
  };

  services = {
    pulseaudio = {
      enable = false;
    };

    pipewire = {
      enable = true;
      audio = {
        enable = true;
      };
      pulse = {
        enable = true;
      };
      wireplumber = {
        enable = true;
        extraConfig = {
          "92-bluetooth-codecs" = {
            "monitor.bluez.properties" = {
              "bluez5.codecs" = ["ldac" "sbc_xq" "sbc" "aac" "lc3" "msbc"];
              "bluez5.a2dp.ldac.quality" = "auto";
              "bluez5.enable-hw-volume" = true;
              "bluez5.roles" = ["a2dp_sink" "a2dp_source" "bap_sink" "bap_source" "hsp_ag" "hfp_ag"];
            };
          };
        };
      };
      jack = {
        enable = true;
      };
      alsa = {
        enable = true;
        support32Bit = true;
      };
      extraConfig = {
        pipewire = {
          "92-low-latency" = {
            "context.properties" = {
              "default.clock.rate" = 48000;
              "default.clock.allowed-rates" = [48000];
              "default.clock.quantum" = 1024;
              "default.clock.min-quantum" = 512;
              "default.clock.max-quantum" = 8192;
            };
          };
        };
      };
    };

    udev = {
      extraRules = ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
      '';
    };
  };
}
