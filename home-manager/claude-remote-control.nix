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
      # A memory kill of one remote session must not stop the server and every other session.
      OOMPolicy = "continue";
      # The lowest a user unit can go (the user manager itself runs at 100, services default to 200).
      # Every session this server starts inherits it, so earlyoom picks other processes first.
      OOMScoreAdjust = 100;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
