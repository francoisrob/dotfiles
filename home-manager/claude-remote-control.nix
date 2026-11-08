{config, ...}: let
  claude = "${config.home.homeDirectory}/.local/bin/claude";
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
