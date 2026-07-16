{
  pkgs,
  user,
  ...
}: {
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    # OpenVPN plugin so .ovpn files import into NetworkManager
    # (nmcli, or the nm-connection-editor GUI).
    plugins = [pkgs.networkmanager-openvpn];
  };

  users.users.${user}.extraGroups = ["networkmanager"];
}
