{user, ...}: {
  virtualisation = {
    docker = {
      rootless = {
        enable = true;
        setSocketVariable = true;
      };
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
