{pkgs, ...}: {
  users = {
    users = {
      francois = {
        isNormalUser = true;
        description = "Francois";
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
