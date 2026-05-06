{
  pkgs,
  lib,
  ...
}: {
  services = {
    solaar = {
      enable = true;
    };

    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
      extraConfig = ''
        storage:
          wiredTiger:
            engineConfig:
              cacheSizeGB: 2
      '';
    };
  };

  # mongodb soft limits
  security = {
    pam = {
      loginLimits = [
        {
          domain = "mongodb";
          item = "nofile";
          type = "-";
          value = "64000";
        }
      ];
    };
  };

  systemd = {
    services = {
      mongodb = {
        wantedBy = lib.mkForce [];
        environment = {
          "GLIBC_TUNABLES" = "glibc.pthread.rseq=0";
        };
      };
      teamviewerd.wantedBy = lib.mkForce [];
    };
  };
}
