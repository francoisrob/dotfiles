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
    # LVFS firmware updates (`fwupdmgr refresh && fwupdmgr update`); covers
    # Dell UEFI/BIOS, SSD, and dock firmware on this machine.
    fwupd.enable = true;

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

    # Target the TEMPLATE, not the instance. uwsm escapes the dash in the
    # instance name, so the live unit is `wayland-wm@hyprland\x2duwsm.desktop
    # .service`, while naming it "wayland-wm@hyprland-uwsm.desktop" here made
    # NixOS generate a differently-named unit that systemd never loads. Verified
    # broken: `systemctl --user show` on the running instance returned
    # OOMPolicy=stop despite this line existing.
    #
    # Correcting the earlier comment here: apps launched WITHOUT `uwsm-app --`
    # do not land in the compositor's cgroup. Hyprland itself runs in the ROOT
    # cgroup, and cgroup membership is inherited across fork, so those apps land
    # in root too (proven with `hyprctl dispatch exec`). Root has no memory
    # knobs and no cgroup for oomd to kill, which is why raw-exec'd apps are the
    # ones no containment scheme can reach. Prefer `uwsm-app --` for anything
    # that might grow.
    user.services."wayland-wm@".serviceConfig = {
      # OOMPolicy=stop would reap the whole unit when the kernel kills one of
      # its children, taking Hyprland down with it.
      OOMPolicy = "continue";
      # Everything in the session inherits oom_score_adj=200: user@.service runs
      # at 100 and the user manager defaults children to its own value +100. So
      # 97 of 337 processes sit at exactly 200, INCLUDING Hyprland, kitty,
      # pipewire and fish, which gives the OOM killer no way to tell a runaway
      # from the compositor. 100 is the floor a user manager can assign (going
      # lower needs CAP_SYS_RESOURCE) and makes Hyprland a less-preferred victim
      # than the apps around it.
      OOMScoreAdjust = 100;
    };
  };
}
