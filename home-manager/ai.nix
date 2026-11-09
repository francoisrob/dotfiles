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

  serverCtx = 65536;

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
    ctx-size = ${toString serverCtx}
    # Host RAM for saved prompts, so the Hermes pane and the ntfy chat both stay cached.
    cache-ram = 4096
    spec-type = draft-mtp
    spec-draft-n-max = 2
    reasoning = off
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
      case "''${1:-}" in
        "") ;;
        --delete) delete=1 ;;
        *) echo "usage: scratch-clean [--delete]" >&2; exit 2 ;;
      esac

      entries() {
        # README.md and .gitkeep are tracked in the hub repo.
        find "$root" -mindepth 1 -maxdepth 1 ! -name claude-tmp ! -name tmp ! -name README.md ! -name .gitkeep -print0
        if [ -d "$root/claude-tmp" ]; then find "$root/claude-tmp" -mindepth 3 -maxdepth 3 -print0; fi
        if [ -d "$root/tmp" ]; then find "$root/tmp" -mindepth 1 -maxdepth 1 -print0; fi
      }

      failures=0
      mapfile -d "" -t found < <(entries)
      wait $! || { echo "scratch-clean: listing $root failed" >&2; failures=$((failures + 1)); }

      for entry in "''${found[@]}"; do
        status=0
        recent=$(find "$entry" -newermt "-60 days" -print -quit) || status=$?
        if [ -n "$recent" ]; then continue; fi
        if [ "$status" -ne 0 ]; then
          echo "kept $entry (could not read all of it, so its age is unknown)" >&2
          failures=$((failures + 1))
          continue
        fi
        if [ "$delete" = 0 ]; then
          echo "would remove $entry"
        elif rm -rf --one-file-system -- "$entry"; then
          echo "removed $entry"
        else
          echo "failed to remove $entry" >&2
          failures=$((failures + 1))
        fi
      done

      [ "$failures" -eq 0 ]
    '';
    checkPhase = ''
      ${pkgs.stdenv.shellDryRun} "$target"
      ${lib.getExe pkgs.shellcheck} "$target"
      ${lib.getExe pkgs.bash} ${../tests/scratch-clean/test.sh} "$target"
    '';
  };

  homeDir = config.home.homeDirectory;
  isHub = hostName == "minipc";

  agentGuard = pkgs.callPackage ../modules/pkgs/agent-guard {};

  # The Ovis plugin builds with bun and node. They come first on the PATH that herdr hands to every pane.
  herdr = pkgs.symlinkJoin {
    name = "herdr-${pkgs.herdr.version}";
    paths = [pkgs.herdr];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = "wrapProgram $out/bin/herdr --prefix PATH : ${lib.makeBinPath [pkgs.bun pkgs.nodejs]}";
    meta.mainProgram = "herdr";
  };

  # Push channel for Hermes. Users and tokens come from ~/.config/ntfy/secrets.env.
  ntfyConfig = (pkgs.formats.yaml {}).generate "ntfy-server.yml" {
    base-url = "https://ntfy.francoisrob.me";
    listen-http = "127.0.0.1:2586";
    behind-proxy = true;
    cache-file = "${homeDir}/.local/state/ntfy-server/cache.db";
    auth-file = "${homeDir}/.local/state/ntfy-server/user.db";
    auth-default-access = "deny-all";
    # kill-alerts is the publish-only user of the system kill-alerts service (memory kills, crashes).
    auth-access = ["francois:hermes:rw" "francois:alerts:ro" "kill-alerts:alerts:wo"];
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
        # Hermes otherwise reads 262144 from the GGUF metadata.
        context_length = serverCtx;
      };
      providers.llamacpp = {
        base_url = "http://127.0.0.1:3080/v1";
        api_key = "local";
        model = "Ornith-1.5-9B-Q5_K_M";
      };
      memory.provider = "axiom";
      # Hermes otherwise downloads its own Chromium, which cannot run on NixOS.
      browser.executable_path = "${pkgs.chromium}/bin/chromium";
      agent.max_turns = 40;
      tool_loop_guardrails = {
        hard_stop_enabled = true;
        warn_after = {
          exact_failure = 2;
          same_tool_failure = 3;
          idempotent_no_progress = 2;
        };
        hard_stop_after = {
          exact_failure = 5;
          same_tool_failure = 8;
          idempotent_no_progress = 5;
        };
      };
      # Hermes requires a window of at least 64000, so the margin comes from compressing at 42000 tokens,
      # well before the server window fills.
      compression = {
        threshold_tokens = 42000;
        context_timeout_seconds = 300;
        context_total_ceiling_seconds = 1200;
      };
      plugins.enabled = ["herdr-agent-state"];
      # The full default bundle on both channels. Set explicitly: the config merge keeps old keys.
      platform_toolsets = {
        cli = ["hermes-cli"];
        ntfy = ["hermes-cli"];
      };
    };
    # NTFY_* settings and token, kept out of the repo.
    environmentFiles = ["${config.home.homeDirectory}/.config/hermes/secrets.env"];
  };

  systemd.user.services.hermes-agent = lib.mkIf config.services.hermes-agent.gateway.enable {
    Unit = {
      Wants = ["llama-server.service" "systemd-tmpfiles-setup.service"];
      After = ["llama-server.service" "systemd-tmpfiles-setup.service"];
    };
    Service = {
      Environment = ["TMPDIR=${scratchTmp}"];
      OOMScoreAdjust = 100;
      # Exit 75 is the gateway asking to be restarted. Exit 1 is how it ends after SIGTERM
      # (a stop or a switch), so that the service manager revives it.
      SuccessExitStatus = [1 75];
      RestartForceExitStatus = [75];
    };
  };

  home.packages = [
    pkgs.llama-cpp-vulkan
    pkgs.python3Packages.huggingface-hub
    scratchClean
    herdr
    pkgs.ntfy-sh
  ];

  # herdr server at boot without login; Ovis runs inside it as a herdr plugin.
  systemd.user.services.herdr = lib.mkIf isHub {
    Unit = {
      Description = "herdr server (agent panes, Ovis plugin)";
      Wants = ["systemd-tmpfiles-setup.service"];
      After = ["systemd-tmpfiles-setup.service"];
      # Never give up restarting after a crash.
      StartLimitIntervalSec = 0;
      # A home-manager switch must not restart herdr: that ends every agent pane.
      # Changes to this unit take effect the next time herdr starts.
      X-SwitchMethod = "keep-old";
    };
    Service = {
      ExecStart = "${herdr}/bin/herdr server";
      WorkingDirectory = "%h/hub";
      Environment = ["TMPDIR=${scratchTmp}"];
      Restart = "on-failure";
      RestartSec = 5;
      # Every pane process lives in this unit. When the kernel kills one of them for memory,
      # keep herdr and the other panes running instead of stopping the whole unit (the default).
      OOMPolicy = "continue";
      OOMScoreAdjust = 100;
    };
    Install.WantedBy = ["default.target"];
  };

  # Relaunches an agent chat in its own pane, resuming the same session, when earlyoom or the
  # kernel kills that agent for memory. herdr itself only resumes chats when the server restarts.
  # Its outcomes reach the phone through the kill-alerts system service.
  systemd.user.services.agent-revive = lib.mkIf isHub {
    Unit = {
      Description = "Relaunch herdr agent chats killed for memory";
      Wants = ["herdr.service"];
      After = ["herdr.service"];
      StartLimitIntervalSec = 0;
    };
    Service = {
      # -E -s ignore the environment and user site; the script directory (in the store) stays importable.
      ExecStart = "${agentGuard.python}/bin/python3 -E -s ${agentGuard}/lib/agent_revive.py --journalctl ${pkgs.systemd}/bin/journalctl --socket %h/.config/herdr/herdr.sock";
      SyslogIdentifier = "agent-revive";
      Restart = "always";
      RestartSec = 5;
      MemoryMax = "128M";
    };
    Install.WantedBy = ["default.target"];
  };

  systemd.user.services.ntfy = lib.mkIf isHub {
    Unit.Description = "ntfy push server (127.0.0.1:2586, tailnet via Caddy)";
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
    };
    Service = {
      Type = "simple";
      # --sleep-idle-seconds: after 2 hours with no request the model leaves RAM and GPU memory;
      # the next request reloads it. A request in progress never counts as idle.
      ExecStart = "${pkgs.llama-cpp-vulkan}/bin/llama-server --models-dir ${modelsDir} --models-preset ${presets} --models-max 1 --sleep-idle-seconds 7200 --host 127.0.0.1 --port 3080 --api-key local";
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
