{
  config,
  pkgs,
  hostName,
  ...
}: let
  tailscaleIp = "100.116.70.67";
  domain = "${hostName}.taile52872.ts.net";
  port = 8080;
  certDir = "/var/lib/webdav-cert";
  inherit (config.services.webdav) group;
in {
  services.webdav = {
    enable = true;
    environmentFile = "/etc/webdav.env";
    settings = {
      address = tailscaleIp;
      inherit port;
      tls = true;
      cert = "${certDir}/cert.pem";
      key = "${certDir}/key.pem";
      directory = "/srv/seedvault";
      permissions = "CRUD";
      users = [
        {
          username = "seedvault";
          password = "{env}SEEDVAULT_PASSWORD";
        }
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/seedvault 0700 ${config.services.webdav.user} ${group} -"
    "d ${certDir} 0750 root ${group} -"
  ];

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [port];

  systemd.services.webdav = {
    after = ["tailscaled.service" "webdav-cert.service"];
    wants = ["tailscaled.service" "webdav-cert.service"];
    serviceConfig.RestartSec = "10s";
  };

  systemd.services.webdav-cert = {
    description = "Fetch the Tailscale TLS certificate for WebDAV";
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    path = [config.services.tailscale.package pkgs.diffutils];
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "30s";
    };
    script = ''
      cd ${certDir}
      tailscale cert --cert-file cert.pem.new --key-file key.pem.new ${domain}
      if cmp -s cert.pem.new cert.pem; then
        rm cert.pem.new key.pem.new
        exit 0
      fi
      chgrp ${group} cert.pem.new key.pem.new
      chmod 0640 cert.pem.new key.pem.new
      mv -f key.pem.new key.pem
      mv -f cert.pem.new cert.pem
      systemctl try-restart --no-block webdav.service
    '';
  };

  systemd.timers.webdav-cert = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
