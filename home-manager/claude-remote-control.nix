{config, ...}: let
  claude = "${config.home.homeDirectory}/.local/bin/claude";

  # Remote Control spawns ordinary Claude Code sessions, so whatever is on this
  # PATH is the toolchain those sessions get. A systemd user unit starts from an
  # almost empty environment: the rich PATH that `systemctl --user
  # show-environment` reports is imported by the Hyprland/uwsm login, which has
  # not happened yet when the service starts. Spelling out the profile order (the
  # same order a login shell builds it) keeps a phone-started session identical
  # to a terminal-started one instead of "git: command not found".
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
  # `claude remote-control` (alias `claude rc`) is a persistent server that lets
  # claude.ai/code and the Claude mobile app drive Claude Code sessions on this
  # machine. It serves ONE directory -- ~/hub here -- and pre-creates a session
  # on start, then accepts up to 32 concurrent ones in that same directory.
  #
  # The binary is the native installer's build under ~/.local/share/claude, not a
  # nixpkgs package, so this unit only supervises the process; `claude install`
  # still owns updating it. Auth comes from ~/.claude/.credentials.json (a plain
  # file, no keyring), which is why this works with no graphical session.
  #
  # Scope note: user units die with the last login session. `loginctl
  # enable-linger francois` (or `users.users.francois.linger = true` on the
  # system side) is what makes it survive logout and start at boot.
  systemd.user.services.claude-remote-control = {
    Unit = {
      Description = "Claude Code Remote Control server (~/hub)";
      Documentation = "https://claude.ai/code";
    };

    Service = {
      Type = "simple";
      WorkingDirectory = "${config.home.homeDirectory}/hub";

      # bypassPermissions: sessions started from the phone run every tool without
      # asking. Deliberate -- there is nobody at this keyboard to approve them --
      # but it does mean anyone holding the Claude account can run arbitrary
      # commands as francois on this box.
      ExecStart = "${claude} remote-control --permission-mode bypassPermissions";

      Environment = ["PATH=${profilePath}"];

      # The server paints a live TUI status block on stdout and repaints it about
      # once a second whether or not it has a TTY. Into the journal that is ~86k
      # blocks of escape sequences a day, so stdout is dropped. stderr stays on
      # the journal: it is silent in normal operation, so anything landing there
      # is a real fault. For a session-level trace, append
      # `--debug-file %h/.local/state/claude-remote-control.log` to ExecStart.
      StandardOutput = "null";
      StandardError = "journal";

      # The link to api.anthropic.com is long-lived, so the expected failure is a
      # dropped connection rather than a crash. Always come back, with a pause
      # long enough that a network outage does not spin.
      Restart = "always";
      RestartSec = 10;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
