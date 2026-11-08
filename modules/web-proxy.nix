# Tailnet-only HTTPS names under francoisrob.me. The DNS records point at this host's tailnet IP,
# so the names lead nowhere from the internet. Certificates come from Let's Encrypt over the
# Cloudflare DNS challenge (CF_API_TOKEN), so no port is opened to the internet.
{
  config,
  lib,
  pkgs,
  ...
}: let
  tailscaleIp = "100.116.70.67";
  authSocket = config.services.tailscaleAuth.socketPath;

  # Ask tailscaled who the visitor is. Tagged devices and unknown peers are refused; the login is
  # handed on as Tailscale-User-Login, the header `tailscale serve` sets and Ovis trusts.
  tailnetLogin = ''
    request_header -Tailscale-User-Login
    forward_auth unix/${authSocket} {
      uri /
      header_up Remote-Addr {remote_host}
      header_up Remote-Port {remote_port}
      copy_headers Tailscale-User>Tailscale-User-Login
    }
  '';

  site = upstream: extra: ''
    route {
      ${tailnetLogin}
      reverse_proxy ${upstream} {
        ${extra}
      }
    }
  '';
in {
  services.tailscaleAuth = {
    enable = true;
    group = "caddy";
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy.withPlugins {
      plugins = ["github.com/caddy-dns/cloudflare@v0.2.4"];
      hash = "sha256-tubXIDCJnO2mvdnPlZclwDhNGaeeYLSt7lnni3+pXDo=";
    };
    environmentFile = "/home/francois/.config/caddy/cloudflare.env";
    globalConfig = ''
      default_bind ${tailscaleIp}
      acme_dns cloudflare {env.CF_API_TOKEN}
    '';
    virtualHosts = {
      "ovis.francoisrob.me".extraConfig = site "127.0.0.1:7317" "";
      "ntfy.francoisrob.me".extraConfig = site "127.0.0.1:2586" "";
      "freellmapi.francoisrob.me".extraConfig = site "127.0.0.1:3001" "";
      # The portal stays on terraria; its own `tailscale serve` address is the upstream.
      "axiom.francoisrob.me".extraConfig = site "https://terraria.taile52872.ts.net" "header_up Host terraria.taile52872.ts.net";
    };
  };

  systemd.services.caddy = {
    after = ["tailscaled.service" "tailscale-nginx-auth.socket"];
    wants = ["tailscaled.service"];
    # Caddy exits without a restart when it cannot bind, and the tailnet IP appears a moment after
    # tailscaled starts, so wait for it (up to the default 90 s start timeout).
    serviceConfig.ExecStartPre = "${pkgs.bash}/bin/sh -c 'until ${pkgs.iproute2}/bin/ip -4 addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q ${tailscaleIp}/; do sleep 1; done'";
  };
}
