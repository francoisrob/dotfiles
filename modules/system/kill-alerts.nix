{
  config,
  pkgs,
  user,
  ...
}: let
  agentGuard = pkgs.callPackage ../pkgs/agent-guard {};

  # Units whose every stop, restart or failure is worth a phone ping.
  watched = [
    "herdr.service"
    "agent-revive.service"
    "llama-server.service"
    "claude-remote-control.service"
    "hermes-agent.service"
    "earlyoom.service"
  ];
in {
  # Follows the journal and pushes every memory kill (earlyoom, kernel, oomd), every agent-revive
  # outcome and every stop, crash or restart of the watched units to the ntfy "alerts" topic.
  systemd.services.kill-alerts = {
    description = "Push memory kills and service crashes to ntfy";
    wantedBy = ["multi-user.target"];
    after = ["systemd-journald.service"];
    serviceConfig = {
      ExecStart = toString ([
          # -E -s ignore the environment and user site; the script directory (in the store) stays importable.
          "${agentGuard.python}/bin/python3 -E -s ${agentGuard}/lib/kill_alerts.py"
          "--journalctl ${config.systemd.package}/bin/journalctl"
          "--url http://127.0.0.1:2586"
          "--topic alerts"
          "--token-file %d/ntfy-token"
          "--cursor-file %S/kill-alerts/cursor"
        ]
        ++ map (u: "--watch ${u}") watched);
      # The publish-only ntfy token, kept out of the Nix store. systemd reads it as root.
      LoadCredential = "ntfy-token:${config.users.users.${user}.home}/.config/ntfy/kill-alerts.token";
      StateDirectory = "kill-alerts";
      Restart = "always";
      RestartSec = 5;
      # The alerter must outlive whatever it reports on.
      OOMScoreAdjust = -900;
      MemoryMax = "128M";

      DynamicUser = true;
      # Read access to the system and user journals.
      SupplementaryGroups = ["systemd-journal"];
      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      ProtectClock = true;
      ProtectHostname = true;
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      LockPersonality = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = ["@system-service" "~@privileged"];
      # Only the local ntfy server.
      RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
      IPAddressAllow = "localhost";
      IPAddressDeny = "any";
    };
  };
}
