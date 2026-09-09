{
  pkgs,
  user,
  ...
}: {
  users = {
    defaultUserShell = pkgs.bash;
    users = {
      ${user} = {
        isNormalUser = true;
        description = user;

        # Start this user's systemd --user manager at boot and keep it running
        # after the last logout, instead of tying it to a login session. What
        # needs it is claude-remote-control.service (home-manager/claude-remote
        # -control.nix): the phone and claude.ai reach this machine only while
        # that server is up, which is exactly when nobody is sitting here.
        linger = true;
        extraGroups = [
          "wheel"
          "video"
          "audio"
          "lp"
          "scanner"
          "storage"
          "gamemode" # allow feral gamemode to renice/raise CPU governor
        ];
        shell = pkgs.fish;
      };
    };
  };
}
