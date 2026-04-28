{user, ...}: {
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  users.users.${user}.extraGroups = ["networkmanager"];
}
