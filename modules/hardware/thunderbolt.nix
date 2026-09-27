# Thunderbolt/USB4 device authorization.
#
# minipc reaches its second display through a USB4 DisplayPort tunnel rather
# than a direct video cable: the Dell U2724DE is a Thunderbolt 4 hub monitor
# and enumerates as thunderbolt device 0-2 (vendor 0xd4, device 0xc045,
# generation 4, 20.0 Gb/s on 2 lanes) with a retimer at 0-2:1.1.
#
# The domain security level is "user", which means a device stays at
# authorized=0 until something explicitly approves it. Nothing ever did: bolt
# was not enabled and boltctl was not installed, so the monitor ran
# indefinitely unauthorized. DisplayPort tunnelling is not gated by that
# check, so the screen kept showing a picture and the half-initialized state
# went unnoticed for months.
#
# bolt is the userspace daemon that does the approving. It stores a per-device
# key on first enrollment and reauthorizes automatically on every later plug,
# so the device comes up the same way on every boot.
#
# There is no GNOME Thunderbolt panel in a Hyprland session, so nothing will
# prompt. After the first `nixos-rebuild switch` the device has to be enrolled
# once, by hand:
#
#   boltctl list                                        # confirm it is seen
#   boltctl enroll 47ad8780-00f0-980c-ffff-ffffffffffff # the U2724DE
#
# Thereafter `boltctl list` should report it as authorized, and
# /sys/bus/thunderbolt/devices/0-2/authorized should read 1 rather than 0.
#
# Context: investigated 2026-09-20 after a run of spontaneous hard resets on
# this host, one of which landed 53 ms after a display wake re-trained the
# DisplayPort links. Enabling bolt fixes the unauthorized state on its own
# merits; it is not by itself a proven fix for those resets.
{
  services.hardware.bolt.enable = true;
}
