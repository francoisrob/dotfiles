{
  config,
  lib,
  pkgs,
  inputs,
  hostName,
  ...
}: let
  scratchTmp = "${config.home.homeDirectory}/hub/scratch/tmp";

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
        # README.md and .gitkeep are tracked in the hub repo.
        find "$root" -mindepth 1 -maxdepth 1 ! -name claude-tmp ! -name tmp ! -name README.md ! -name .gitkeep -print0
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

  homeDir = config.home.homeDirectory;
  isHub = hostName == "minipc";

  # systemd user services start with a bare PATH; herdr panes and the Ovis plugin build need the login one.
  agentPath = lib.concatStringsSep ":" (
    map (d: "${homeDir}/${d}") [
      ".pi/agent/bin"
      ".local/share/mise/installs/bun/latest/bin"
      ".local/share/mise/installs/node/latest/bin"
      ".local/share/mise/shims"
      ".local/bin"
      ".local/share/bun/bin"
      ".local/share/npm/bin"
      ".cargo/bin"
      ".nix-profile/bin"
    ]
    ++ [
      "/run/wrappers/bin"
      "/etc/profiles/per-user/${config.home.username}/bin"
      "/nix/var/nix/profiles/default/bin"
      "/run/current-system/sw/bin"
    ]
  );

  # Push channel for Hermes. Users and tokens come from ~/.config/ntfy/secrets.env.
  ntfyConfig = (pkgs.formats.yaml {}).generate "ntfy-server.yml" {
    base-url = "https://ntfy.francoisrob.me";
    listen-http = "127.0.0.1:2586";
    behind-proxy = true;
    cache-file = "${homeDir}/.local/state/ntfy-server/cache.db";
    auth-file = "${homeDir}/.local/state/ntfy-server/user.db";
    auth-default-access = "deny-all";
    auth-access = ["francois:hermes:rw"];
    enable-signup = false;
  };
in {
  imports = [inputs.hermes-agent.homeManagerModules.default];

  programs.hermes-agent.enable = true;

  services.hermes-agent = {
    enable = true;
    package = inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.messaging;
    # A messaging channel can only be served from one machine.
    gateway.enable = isHub;
    settings = {
      model = {
        provider = "llamacpp";
        default = "Ornith-1.5-9B-Q5_K_M";
        # llama-server's ctx-size; Hermes otherwise reads 262144 from the GGUF metadata.
        context_length = 65536;
      };
      providers.llamacpp = {
        base_url = "http://127.0.0.1:3080/v1";
        api_key = "local";
        model = "Ornith-1.5-9B-Q5_K_M";
      };
      memory.provider = "axiom";
    };
    # NTFY_* settings and token, kept out of the repo.
    environmentFiles = ["${config.home.homeDirectory}/.config/hermes/secrets.env"];
  };

  systemd.user.services.hermes-agent = lib.mkIf config.services.hermes-agent.gateway.enable {
    Service.Environment = ["TMPDIR=${scratchTmp}"];
  };

  home.packages = [
    pkgs.llama-cpp-vulkan
    pkgs.python3Packages.huggingface-hub
    scratchClean
    pkgs.herdr
    pkgs.ntfy-sh
  ];

  # herdr server at boot without login; Ovis runs inside it as a herdr plugin.
  systemd.user.services.herdr = lib.mkIf isHub {
    Unit.Description = "herdr server (agent panes, Ovis plugin)";
    Service = {
      ExecStart = "${pkgs.herdr}/bin/herdr server";
      WorkingDirectory = "%h/hub";
      Environment = ["PATH=${agentPath}"];
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.ntfy = lib.mkIf isHub {
    Unit.Description = "ntfy push server (127.0.0.1:2586, tailnet via tailscale serve :9443)";
    Service = {
      ExecStart = "${pkgs.ntfy-sh}/bin/ntfy serve --config ${ntfyConfig}";
      EnvironmentFile = "%h/.config/ntfy/secrets.env";
      StateDirectory = "ntfy-server";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = ["default.target"];
  };

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
