# GMKtec NucBox EVO-X1: Ryzen AI 9 HX 370 (Strix Point, 12c/24t) with a
# Radeon 890M iGPU and no discrete GPU. Unencrypted ext4 root, always on AC,
# no battery, no lid, no internal panel -- so none of the laptop power/display
# machinery in modules/system/laptop.nix is imported here.
{lib, ...}: {
  imports = [
    ./hardware-configuration.nix

    # Hardware
    ../../modules/hardware/cpu/amd.nix
    ../../modules/hardware/gpu/amd.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix

    # Programs
    ../../modules/programs/steam.nix
    ../../modules/programs/thunar.nix

    # System
    ../../modules/system/boot.nix
    ../../modules/system/fonts.nix
    ../../modules/system/graphics.nix
    ../../modules/system/networking.nix

    # Virtualization
    ../../modules/virtualisation/default.nix
    ../../modules/virtualisation/docker.nix

    # Desktop
    ../../modules/desktop.nix

    # Development
    ../../modules/development

    ../../modules/packages.nix
    ../../modules/services.nix
    ../../modules/user.nix
  ];

  # Wi-Fi. This host is stationary, has no ethernet run to it, and sits at
  # -72 dBm from the nearest Helderspruit AP with ~10% TX retries. Both of
  # the faults diagnosed on 2026-08-13 are fixed here, in the host file,
  # rather than in the shared modules, because both are properties of THIS
  # box's placement and not of the fleet.

  # Fault 1: NetworkManager and iwd keep two copies of one PSK. NM stores it
  # (psk-flags=0) and provisions iwd over D-Bus, while iwd also persists
  # /var/lib/iwd/<ssid>.psk itself. During a service restart iwd read that
  # file mid-rewrite, logged "Error loading /var/lib/iwd//Helderspruit.psk",
  # and sat in a connect-failed status:1 loop across every BSS until it was
  # restarted by hand. wpa_supplicant is NetworkManager's default backend and
  # keeps a single credential store, so that race cannot occur.
  #
  # Fault 2: modules/system/boot.nix sets RoamThreshold5G = -70 for iwd, which
  # is ABOVE the -72..-78 this desk actually receives on 5GHz. iwd therefore
  # treated 5GHz as permanently unacceptable and fired a roam scan every
  # RoamRetryInterval (60s) forever: 223 roams and 19 dropped associations in
  # 7 days, each one a deauth/reauth/reassoc gap. Those thresholds were tuned
  # against a -18 dBm reading that no direct scan can reproduce (that BSS
  # measures -77..-80), so they were built on a bad number. Dropping iwd here
  # retires that tuning for this host; the block stays in boot.nix untouched.
  networking.wireless.iwd.enable = lib.mkForce false;

  networking.networkmanager.wifi = {
    backend = lib.mkForce "wpa_supplicant";

    # The AP issued 36 reason-4 (disassociated due to inactivity) deauths in
    # 7 days. Power save lets the radio miss the AP's keepalives on a link
    # this marginal. This box is always on AC with no battery, so there is
    # nothing to trade away by leaving the receiver up.
    powersave = false;

    # A stationary host that re-randomises its MAC per scan presents as a new
    # client to AP-side band steering and to DHCP every time. Keep it stable.
    scanRandMacAddress = false;
  };

  # Intel AX200 firmware power management. power_scheme=1 is CAM ("continuously
  # active"), which stops the firmware parking the receiver between beacons;
  # 336 "missed beacons exceeds threshold" events were logged in a single day
  # at this signal level. Module parameters are read only at module load, so
  # this takes effect on the next REBOOT, not on a nixos-rebuild switch.
  boot.extraModprobeConfig = ''
    options iwlmvm power_scheme=1
  '';

  # Split-lock detection traps a thread whenever it does an atomic operation
  # that straddles a cache line, then serialises the whole memory bus while it
  # sorts it out. Steam's CHTTPClientThread does this constantly: the journal
  # for one uptime carried hundreds of "took a bus_lock trap" lines plus
  # "handle_bus_lock: N callbacks suppressed". Each trap is a real stall, not
  # just log noise. Turning detection off restores full speed for the offending
  # process. The feature only ever reports and penalises other people's
  # misaligned atomics, so on a single-user desktop there is nothing to lose.
  boot.kernelParams = ["split_lock_detect=off"];
}
