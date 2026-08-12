# Gaming performance stack for this Optimus laptop (Intel Iris Xe + NVIDIA MX350).
#
# feral gamemode is the core: on game launch it switches the CPU governor to
# `performance`, renices the game, and inhibits the screensaver. Its custom
# start/end hooks also run gaming-mode.sh, which (a) drops the secondary monitor
# to 60Hz via kanshi and (b) strips Hyprland eye-candy (blur/shadows/animations)
# to free the Intel iGPU that composites the game's output. See that script's
# header for why the monitor part goes through kanshi instead of hyprctl.
#
# A game only triggers all this if launched via `gamemoderun`:
#   * Steam  -> launch options:  gamemoderun mangohud %command%
#               (add `nvidia-offload` in front ONLY for GPU-heavy 3D titles; for
#                light/2D games like Terraria, plain Iris Xe beats routing through
#                the weak MX350 + PRIME copy, so leave offload OFF for those.)
#   * Lutris -> per-game/runner options: enable "Feral GameMode" + "MangoHud".
{
  pkgs,
  user,
  ...
}: {
  programs = {
    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
          inhibit_screensaver = 1;
        };
        custom = {
          start = "${pkgs.bash}/bin/bash /home/${user}/.config/hypr/scripts/gaming-mode.sh on";
          end = "${pkgs.bash}/bin/bash /home/${user}/.config/hypr/scripts/gaming-mode.sh off";
        };
      };
    };

    # Micro-compositor: lets you cap fps / upscale / isolate a game to one output.
    # Run a game under it with e.g. `gamescope -W 2560 -H 1440 -r 120 -- %command%`.
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  # MangoHud performance overlay (toggle in-game with Shift+F12 under Proton).
  environment.systemPackages = with pkgs; [
    mangohud
  ];
}
