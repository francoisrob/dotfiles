{
  config,
  lib,
  pkgs,
  user,
  hostName,
  ...
}: {
  networking = {
    inherit hostName;
    useDHCP = false;
    resolvconf.enable = false;
    networkmanager = {
      enable = true;
      plugins = [pkgs.networkmanager-openvpn];
    };
    firewall = {
      enable = true;
      trustedInterfaces = [config.services.tailscale.interfaceName];
    };
    nftables.enable = true;
  };

  boot = {
    kernelModules = ["tcp_bbr"];
    kernel.sysctl = {
      "net.core.rmem_max" = 16777216;
      "net.core.wmem_max" = 16777216;
      "net.ipv4.tcp_rmem" = "4096 87380 16777216";
      "net.ipv4.tcp_wmem" = "4096 87380 16777216";
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
    };
  };

  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

  services = {
    resolved.enable = true;
    tailscale = {
      enable = true;
      openFirewall = true;
    };
  };

  users.users.${user}.extraGroups = ["networkmanager"];
}
