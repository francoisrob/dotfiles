{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      alsa-utils
    ];
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
              "default.clock.rate" = 44100;
              "default.clock.quantum" = 1024;
              "default.clock.min-quantum" = 512;
              "default.clock.max-quantum" = 8192;
            };
          };
          "92-bluetooth-codecs" = {
            "bluez5.codecs" = ["sbc" "aac" "ldac"];
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
