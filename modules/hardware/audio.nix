{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      alsa-utils
    ];

    # PipeWire/WirePlumber's spa-alsa needs to find UCM configs to expose
    # HiFi profiles for SOF/HDA cards (otherwise only "off" + "pro-audio"
    # show up and the sink falls back to dummy output).
    sessionVariables = {
      ALSA_CONFIG_UCM2_DIR = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
    };
  };

  systemd.user = let
    ucmEnv = {
      ALSA_CONFIG_UCM2_DIR = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
    };
    # PipeWire user units start for every user session, including greetd's
    # `greeter` (system user, HOME=/var/empty), whose wireplumber fails state
    # writes on every boot. Restrict the audio stack to real users.
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
              # Keep the graph at 48 kHz on this Tiger Lake SOF/HDA laptop.
              # Forcing 44.1 kHz started tripping hw_params failures after the
              # recent kernel update and resulted in silent internal audio.
              "default.clock.rate" = 48000;
              "default.clock.allowed-rates" = [48000];
              "default.clock.quantum" = 1024;
              "default.clock.min-quantum" = 512;
              "default.clock.max-quantum" = 8192;
            };
          };
          "92-bluetooth-codecs" = {
            # lc3 is the LE Audio (BAP) codec — without it WirePlumber only
            # offers Classic A2DP/HFP, so a mic-using app (voice call) forces
            # HFP and lands on mSBC. lc3 enables the bap-duplex profile:
            # high-quality audio + mic in one LE Audio stream. sbc_xq lifts
            # A2DP voice quality on the Classic fallback.
            "bluez5.codecs" = ["sbc" "sbc_xq" "aac" "ldac" "lc3"];
            "bluez5.a2dp.ldac.quality" = "auto";
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
