{
  config,
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

  # Tailscale: a WireGuard mesh between this account's own devices (the phone,
  # this host, the frenchman VPS), so the phone can reach this box from
  # anywhere without SSH being exposed to the internet. Enrolling a host is a
  # one-off: `sudo tailscale up`, open the printed URL, log in. The node key
  # that produces lives in /var/lib/tailscale and survives rebuilds and
  # reboots, so nothing here needs a secret. DNS integration goes through
  # systemd-resolved (boot.nix), which is the mode Tailscale recommends on
  # Linux: only *.ts.net names are routed to it, everything else is untouched.
  services.tailscale = {
    enable = true;
    # Open UDP 41641 (services.tailscale.port) so peers can reach this node
    # directly. Without it every session rides Tailscale's DERP relays, which
    # works but adds latency. WireGuard silently drops anything that is not a
    # valid handshake from a known peer, so the open port exposes nothing.
    openFirewall = true;
  };

  # Every packet on tailscale0 was authenticated and decrypted by WireGuard
  # before the firewall sees it, and the tailnet holds only this account's own
  # devices, so treat the interface like the loopback: anything listening on
  # this host is reachable from the phone (SSH, a dev server on :3000) without
  # a per-port firewall edit. The physical interfaces keep their normal
  # allowlist. Tighten to `networking.firewall.interfaces.tailscale0
  # .allowedTCPPorts = [22]` if that ever feels too broad.
  networking.firewall.trustedInterfaces = [config.services.tailscale.interfaceName];

  users.users.${user}.extraGroups = ["networkmanager"];
}
