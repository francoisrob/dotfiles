{
  pkgs,
  user,
  ...
}: {
  imports = [
    ./docker.nix
  ];

  virtualisation = {
    libvirtd = {
      # Kept off until VMs are needed (flip to true + rebuild). Docker is
      # independent: it lives in docker.nix with its own daemon.
      enable = false;
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        swtpm = {
          enable = true;
        };
      };
    };
    spiceUSBRedirection = {
      enable = true;
    };
  };
  systemd = {
    services = {
      "user@" = {
        serviceConfig = {
          Delegate = "cpu cpuset io memory pids";
        };
      };
    };
  };
  users = {
    users = {
      ${user} = {
        extraGroups = [
          "libvirtd"
          "kvm"
        ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
    ];
  };

  programs = {
    dconf = {
      enable = true;
    };
    virt-manager = {
      enable = true;
    };
  };
}
