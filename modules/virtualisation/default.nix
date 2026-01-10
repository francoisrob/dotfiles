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
      enable = true;
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
  nixpkgs.overlays = [
    (final: prev: {
      libvirt = prev.libvirt.override {
        enableXen = false;
        enableGlusterfs = false;
        enableIscsi = false;
      };
    })
  ];
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
