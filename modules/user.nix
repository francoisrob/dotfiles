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

        linger = true;
        extraGroups = [
          "wheel"
          "video"
          "audio"
          "lp"
          "scanner"
          "storage"
          "gamemode"
        ];
        shell = pkgs.fish;
      };
    };
  };
}
