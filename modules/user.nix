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
