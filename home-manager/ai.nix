{
  config,
  pkgs,
  ...
}: let
  modelsDir = "${config.home.homeDirectory}/.local/share/models";

  presets = pkgs.writeText "llama-models.ini" ''
    version = 1

    [*]
    n-gpu-layers = 99
    flash-attn = on
    jinja = true
    parallel = 1
    cache-type-k = q8_0
    cache-type-v = q8_0

    [Ornith-1.5-9B-Q5_K_M]
    load-on-startup = true
    ctx-size = 65536
    cache-ram = 2048
    spec-type = draft-mtp
    spec-draft-n-max = 2
    chat-template-kwargs = {"enable_thinking":false}
    temp = 0.6
    top-p = 0.95
    top-k = 20
  '';

  scratchClean = pkgs.writeShellApplication {
    name = "scratch-clean";
    runtimeInputs = [pkgs.coreutils pkgs.findutils];
    text = ''
      root="$HOME/hub/scratch"
      delete=0
      [ "''${1:-}" = "--delete" ] && delete=1

      units() {
        find "$root" -mindepth 1 -maxdepth 1 ! -name claude-tmp ! -name tmp -print0
        [ -d "$root/claude-tmp" ] && find "$root/claude-tmp" -mindepth 3 -maxdepth 3 -print0
        [ -d "$root/tmp" ] && find "$root/tmp" -mindepth 1 -maxdepth 1 -print0
        true
      }

      units | while IFS= read -r -d "" unit; do
        [ -n "$(find "$unit" -newermt "-60 days" -print -quit)" ] && continue
        if [ "$delete" = 1 ]; then
          rm -rf --one-file-system -- "$unit"
          echo "removed $unit"
        else
          echo "would remove $unit"
        fi
      done
    '';
  };
in {
  home.packages = [
    pkgs.llama-cpp-vulkan
    pkgs.python3Packages.huggingface-hub
  ];

  systemd.user.tmpfiles.rules = ["d %h/hub/scratch/tmp 0700 - - -"];

  # Removes each scratch entry (each session dir in claude-tmp, each entry in tmp) once nothing in it was written for 60 days.
  systemd.user.services.scratch-clean = {
    Unit.Description = "Remove agent scratch untouched for 60 days";
    Service = {
      Type = "oneshot";
      ExecStart = "${scratchClean}/bin/scratch-clean --delete";
      Nice = 19;
      IOSchedulingClass = "idle";
    };
  };

  systemd.user.timers.scratch-clean = {
    Unit.Description = "Daily agent scratch cleanup";
    Timer = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
    Install.WantedBy = ["timers.target"];
  };

  systemd.user.services.llama-server = {
    Unit = {
      Description = "llama.cpp router (127.0.0.1:3080)";
      After = ["network-online.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server --models-dir ${modelsDir} --models-preset ${presets} --models-max 1 --host 127.0.0.1 --port 3080 --api-key local";
      Restart = "always";
      RestartSec = 15;
      Nice = 15;
      IOSchedulingClass = "idle";
    };
    Install = {
      WantedBy = ["default.target"];
    };
  };
}
