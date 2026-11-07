{
  config,
  pkgs,
  user,
  ...
}: {
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    plugins = [pkgs.networkmanager-openvpn];
  };

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];

  users.users.${user}.extraGroups = ["networkmanager"];
}
