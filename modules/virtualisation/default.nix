{pkgs, user, ...}: {
  imports = [
    ./docker.nix
  ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        swtpm = {
          enable = true;
        };
        ovmf = {
          enable = true;
        };
        ovmf = {
          packages = [pkgs.OVMFFull.fd];
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

  services = {
    spice-vdagentd = {
      enable = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
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
