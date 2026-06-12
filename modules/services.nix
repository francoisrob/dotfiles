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
