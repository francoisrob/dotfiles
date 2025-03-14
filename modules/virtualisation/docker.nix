{
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
      francois = {
        extraGroups = [
          "docker"
        ];
      };
    };
  };
}
