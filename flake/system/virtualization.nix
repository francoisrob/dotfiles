{...}: {
  virtualisation = {
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    libvirtd.enable = true;
  };
  systemd.services."user@".serviceConfig = {
    Delegate = "cpu cpuset io memory pids";
  };
  users.users.francois.extraGroups = ["libvirtd" "kvm" "docker"];
}
