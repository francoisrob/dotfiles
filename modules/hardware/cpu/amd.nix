# Ryzen AI 9 HX 370 (Strix Point, Zen5 + Zen5c, 12c/24t).
#
# Deliberately minimal. Two things the Intel module does must NOT be carried
# over to this host, and both are omitted rather than translated:
#
#   * services.thermald -- Intel-only. It drives Intel's RAPL/DPTF interfaces
#     and is completely inert on AMD, so enabling it would just be a running
#     daemon that does nothing.
#   * TLP's AC/DC energy-performance split -- TLP is battery-oriented and this
#     machine has no battery. Its ON_AC settings would apply unconditionally
#     while the ON_BAT half is dead config.
#
# Both live in modules/system/laptop.nix, which this host does not import.
#
# No amd_pstate= kernel parameter either: the driver is already in EPP
# ("active") mode on this kernel. Verified on the installer --
# /sys/devices/system/cpu/cpufreq/policy0/scaling_driver reads
# "amd-pstate-epp" with no parameter set, and the amd_pstate_* sysfs knobs are
# present. Forcing amd_pstate=active would be redundant, and the legacy
# "passive"/acpi-cpufreq paths are strictly worse on Zen5.
{pkgs, ...}: {
  boot = {
    kernelModules = [
      "kvm-amd"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      # CPU/SoC temperatures come from the in-kernel k10temp driver; this is
      # just the `sensors` CLI to read them.
      lm_sensors
    ];
  };

  # The XDNA2 NPU at 66:00.1 binds to the in-tree amdxdna driver automatically
  # (in-kernel since 6.14, and confirmed loaded on this box). There is no
  # userspace stack for it in nixpkgs yet -- no XRT, no Ryzen AI runtime -- so
  # there is nothing to enable here. Left as a note so the absence reads as
  # intentional rather than forgotten.
}
