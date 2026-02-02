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
        ];
        shell = pkgs.fish;
      };
    };
  };
}
