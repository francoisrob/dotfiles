{pkgs, ...}: {
  virtualisation = {
    docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        swtpm.enable = true;
        ovmf.enable = true;
        ovmf.packages = [pkgs.OVMFFull.fd];
      };
    };
    spiceUSBRedirection.enable = true;
  };
  systemd.services."user@".serviceConfig = {
    Delegate = "cpu cpuset io memory pids";
  };
  programs.dconf.enable = true;
  users.users.francois.extraGroups = [
    "libvirtd"
    "kvm"
    "docker"
  ];

  services.spice-vdagentd.enable = true;
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    win-virtio
    win-spice
  ];
}
