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
          "networkmanager"
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
