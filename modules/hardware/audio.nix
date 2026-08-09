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
        # bluez5.codecs is a WirePlumber bluez-monitor property, so it MUST
        # live in wireplumber.conf.d. The old copy under pipewire.extraConfig
        # rendered into pipewire.conf.d and was inert (WirePlumber never reads
        # it), which is why a stray ~/.config/wireplumber/51-bluez-codec.conf
        # with `bluez5.codecs = [ ldac ]` silently won and stripped mSBC.
        extraConfig = {
          "92-bluetooth-codecs" = {
            "monitor.bluez.properties" = {
              # msbc is the wideband HFP codec. Without it a mic-using app
              # forces HFP down to CVSD (8 kHz narrowband) call audio. ldac
              # stays the A2DP pick for playback; lc3 enables LE Audio
              # bap-duplex (hi-fi + mic in one stream). sbc_xq lifts the
              # Classic A2DP fallback.
              "bluez5.codecs" = ["ldac" "sbc_xq" "sbc" "aac" "lc3" "msbc"];
              "bluez5.a2dp.ldac.quality" = "auto";
              "bluez5.enable-hw-volume" = true;
              # Upstream default is the full set:
              #   [ a2dp_sink a2dp_source bap_sink bap_source
              #     hsp_hs hsp_ag hfp_hf hfp_ag ]
              # hfp_hf/hsp_hs make this laptop act as a *handsfree unit* that
              # connects to a remote Audio Gateway (a phone). Registering them
              # makes BlueZ probe every connected device for an HFP-AG SDP
              # record; the WH-1000XM6 only offers Handsfree (0x111e), never
              # HandsfreeAudioGateway (0x111f), so bluetoothd logged
              # "Unable to get Hands-Free Voice gateway SDP record: Host is
              # down" once a minute forever - 4,947 error lines in four days,
              # 94% of the journal's errors, enough to evict every prior boot
              # from the 1G SystemMaxUse cap.
              # hfp_ag/hsp_ag stay: those are the roles that give the headset
              # its microphone with this machine as the gateway.
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
