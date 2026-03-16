{user, ...}: {
  virtualisation = {
    docker = {
      enable = true;
      enableOnBoot = false;
    };
  };

  users = {
    users = {
      ${user} = {
        extraGroups = [
          "docker"
        ];
      };
    };
  };
}
