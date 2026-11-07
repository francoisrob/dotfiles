{config, ...}: let
  claude = "${config.home.homeDirectory}/.local/bin/claude";

  profilePath = builtins.concatStringsSep ":" [
    "${config.home.homeDirectory}/.local/bin"
    "/run/wrappers/bin"
    "${config.home.homeDirectory}/.nix-profile/bin"
    "/nix/profile/bin"
    "${config.home.homeDirectory}/.local/state/nix/profile/bin"
    "/etc/profiles/per-user/${config.home.username}/bin"
    "/nix/var/nix/profiles/default/bin"
    "/run/current-system/sw/bin"
  ];
in {
  systemd.user.services.claude-remote-control = {
    Unit = {
      Description = "Claude Code Remote Control server (~/hub)";
      Documentation = "https://claude.ai/code";
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "${config.home.homeDirectory}/hub";

      ExecStart = "${claude} remote-control --permission-mode bypassPermissions";

      Environment = ["PATH=${profilePath}"];

      StandardOutput = "null";
      StandardError = "journal";

      Restart = "always";
      RestartSec = 10;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
