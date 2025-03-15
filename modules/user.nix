{
  pkgs,
  user,
  ...
}: {
  users = {
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
