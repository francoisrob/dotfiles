# Radeon 890M (RDNA 3.5, gfx1150) -- the HX 370's integrated GPU, and the only
# GPU in this machine.
#
# Much shorter than the NVIDIA module because there is no driver to install:
# amdgpu is in-tree and Mesa provides both RADV (Vulkan) and radeonsi
# (OpenGL + VA-API). Notably absent, and intentionally so:
#
#   * services.xserver.videoDrivers -- the session is Wayland/Hyprland, so the
#     Xorg DDX is never loaded. The NVIDIA module needs it; this one does not.
#   * hardware.amdgpu.amdvlk -- AMDVLK is the alternative Vulkan driver and is
#     slower than RADV for essentially all games. Mesa's RADV is the default
#     and the right pick.
#   * Any PRIME / offload configuration -- there is only one GPU, so there is
#     nothing to offload to. `nvidia-offload` has no counterpart here; games
#     just run.
{
  boot = {
    # Load amdgpu in the initrd so the console comes up at native resolution
    # in one step instead of switching modes partway through boot. Matters
    # here because boot.nix sets quiet + consoleLogLevel 0, so a late mode
    # switch shows as a black-screen pause.
    initrd = {
      kernelModules = ["amdgpu"];
    };
  };

  environment = {
    # radeonsi is Mesa's VA-API driver for AMD's VCN media engine. The laptop
    # sets this to "iHD" for Intel; without overriding it per-host, libva
    # probes and can pick the wrong backend.
    sessionVariables = {
      LIBVA_DRIVER_NAME = "radeonsi";
    };
  };

  # ROCm/HIP is deliberately NOT enabled. gfx1150 is not an officially
  # supported ROCm target, so anything built against it needs
  # HSA_OVERRIDE_GFX_VERSION=11.0.0 to run at all, and rocmPackages pulls a
  # multi-gigabyte closure. If local LLM inference is wanted later, add
  # `rocmPackages.clr.icd` to hardware.graphics.extraPackages and set that
  # env var -- but treat it as a separate, tested change rather than carrying
  # the download cost on every rebuild from day one.
}
