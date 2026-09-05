# Everything in modules/system/boot.nix and modules/desktop.nix that only made
# sense on the Dell laptop, pulled out so the mini PC does not inherit it.
#
# The common thread is that each of these depends on hardware the mini PC
# does not have: a battery, a lid, an internal eDP panel, a Thunderbolt dock,
# an Intel SOF audio DSP, or a LUKS-encrypted root. Left in the shared module
# they were not merely useless -- TLP would have applied its ON_AC branch
# unconditionally, thermald would have run as a no-op daemon on AMD, and the
# LUKS allowDiscards line referenced a UUID that does not exist on the mini PC.
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
      # Fallback profile for SOF regressions on Intel laptops. This prefers the
      # legacy HDA driver and may restore playback at the cost of DSP/DMIC
      # features on some machines.
      boot.kernelParams = ["snd_intel_dspcfg.dsp_driver=1"];
    };
  };

  boot = {
    initrd = {
      # Without this the dm-crypt mapper advertises no discard support
      # (DISC-GRAN 0B), so TRIM never reaches the SSD, neither via a discard
      # mount option nor via fstrim.
      luks.devices."luks-42daaaa8-649b-4c1f-b76d-28a33b522eba".allowDiscards = true;
    };

    kernelParams = [
      # Cypress CCGx USB-C controller on the Thunderbolt dock path.
      "ucsi_ccg.skip_ucsi=1"
    ];
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
        # Don't autosuspend the Intel AX201 Bluetooth controller. TLP's default
        # (USB_EXCLUDE_BTUSB=0) powers it down after 2s idle, which causes the
        # controller to fail resume mid-stream — A2DP dropouts and "firmware
        # bug / missing completion reports" glitches on the WH-1000XM6. This
        # also lets the power/control=on udev rule in boot.nix actually stick.
        USB_EXCLUDE_BTUSB = 1;

        # Balanced on AC, deliberately NOT full 'performance': this i7-1165G7 is
        # thermally limited (PL1 unbounded, ~83C at light load, frequent package
        # throttling), so pinning max clocks only raised idle temps without a
        # sustained-throughput gain. balance_performance lets HWP/turbo ramp
        # under load without sitting at Tjmax.
        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        PLATFORM_PROFILE_ON_AC = "balanced";
        # Keep WiFi radio fully awake on AC (explicit; matches TLP default).
        WIFI_PWR_ON_AC = "off";
      };
    };

    # Intel-only: drives RAPL/DPTF. Inert on AMD, which is why the mini PC's
    # CPU module omits it rather than translating it.
    thermald = {
      enable = true;
    };
  };

  # Force eDP-1 back on after Thunderbolt undock via a fresh modesetting commit,
  # because the TB hot-unplug can leave the DRM CRTC in a broken state
  # (D3cold/D0 resume failure) that no wlr-output-management commit recovers.
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
            # Hyprland 0.56 dropped `hyprctl keyword` entirely ("unknown request")
            # and made `hyprctl dispatch` evaluate its argument as Lua. Both calls
            # go through the Lua API now.
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
