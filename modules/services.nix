{
  pkgs,
  lib,
  user,
  config,
  ...
}: {
  environment.systemPackages = [config.services.postgresql.finalPackage];

  services = {
    fwupd.enable = true;

    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
      replSetName = "rs0";
      extraConfig = ''
        storage:
          wiredTiger:
            engineConfig:
              cacheSizeGB: 2
      '';
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
      extensions = ps: [ps.pgvector];

      ensureDatabases = [user];
      ensureUsers = [
        {
          name = user;
          ensureDBOwnership = true;
          ensureClauses.superuser = true;
        }
      ];

      authentication = lib.mkForce ''
        local all postgres            peer map=postgres
        local all +axiom_login        scram-sha-256
        host  all +axiom_login all    reject
        local all all                 peer
        host  all all 127.0.0.1/32    scram-sha-256
        host  all all ::1/128         scram-sha-256
      '';
      settings.password_encryption = "scram-sha-256";
    };
  };

  programs.solaar = {
    enable = true;
    userService.enable = true;
  };

  systemd = {
    services = {
      mongodb = {
        wantedBy = lib.mkForce [];
        serviceConfig = {
          LimitNOFILE = 64000;
        };
      };
      teamviewerd.wantedBy = lib.mkForce [];
    };

    user.services."wayland-wm@".serviceConfig = {
      OOMPolicy = "continue";
      OOMScoreAdjust = 100;
    };
  };
}
