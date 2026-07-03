{
  pkgs,
  lib,
  user,
  config,
  ...
}: {
  # Expose the client tools (psql, pg_dump, createdb, pg_isready, …) on PATH.
  # finalPackage tracks the enabled server version, so they never drift apart.
  environment.systemPackages = [config.services.postgresql.finalPackage];

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

    postgresql = {
      enable = true;
      # Pin the major version explicitly: the data directory lives in
      # /var/lib/postgresql/<version>, so letting the nixpkgs default drift
      # would silently require a dump/restore migration on upgrade.
      package = pkgs.postgresql_18;

      # Provision a role + database matching the login user. The default
      # local-socket auth is "peer", which maps OS user ${user} to the
      # same-named role, so `psql` works out of the box with no password;
      # ensureDBOwnership makes ${user} own the same-named database.
      ensureDatabases = [user];
      ensureUsers = [
        {
          name = user;
          ensureDBOwnership = true;
          ensureClauses.superuser = true;
        }
      ];
    };
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

    # When kernel OOM-killer kills a child of the compositor unit (e.g. an app
    # launched without `uwsm-app --` ends up in this cgroup), the default
    # OOMPolicy=stop reaps the whole unit, taking Hyprland down. Continue keeps
    # the compositor alive on a kernel-OOM event.
    user.services."wayland-wm@hyprland-uwsm.desktop".serviceConfig.OOMPolicy = "continue";
  };
}
