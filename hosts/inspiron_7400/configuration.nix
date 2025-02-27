{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/virtualization.nix
    ../../modules/nixos/hardware-acceleration.nix
    ../../modules/nixos/steam.nix
    ../../modules/nixos/nvidia.nix
    ../../modules/nixos/intel.nix

    ../../modules/nixos/thunar.nix
    ../../modules/nixos/fonts.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 5;
      systemd-boot = {
        enable = true;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      systemd.enable = true;
    };

    kernel = {
      sysctl = {
        "kernel.sysrq" = 502;
        "net.ipv4.tcp_syncookies" = false;
        "vm.swappiness" = 60;
      };
    };

    plymouth.enable = true;
    kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"

      "mitigations=off"

      # high res
      "video=2560x1200"

      "sysrq_always_enabled=1"

      "rcu_nocbs=0-7"
      "pcie_aspm=force"
      "nvme.noacpi=1"
    ];
  };

  systemd = {
    watchdog.rebootTime = "0";
  };

  environment = {
    systemPackages = with pkgs; [
      xdg-user-dirs
      xdg-utils
      uutils-coreutils-noprefix
      findutils
      libva-utils
      pciutils
      acpi
      glibc

      fastfetch
      unzip
      neovim

      btop
      icu

      wget
      stow
      killall

      kitty
      zoxide

      glxinfo
      openssl
      brightnessctl
      pavucontrol
      mpv

      (lutris.override {
        extraLibraries = pkgs: [
          findutils # List library dependencies here
        ];
        extraPkgs = pkgs: [
          # List package dependencies here
        ];
      })

      # Developer
      tmux
      fd
      fzf
      gnumake
      ripgrep
      mongosh
      mongodb-tools
      mono

      lua
      luajitPackages.luarocks
      go
      python3
      cargo

      nixd
      alejandra

      # C development tools
      gcc
      gdb
      cmake
      check
      valgrind

      # Build essentials
      binutils
      pkg-config

      # Optional but useful
      bear # For generating compile_commands.json
      clang-tools # For clangd, static analysis, etc.
    ];
    variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      MANPAGER = "nvim +Man!";
      C_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.glibc}/include";
      CPLUS_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.glibc}/include:${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}";
    };
    pathsToLink = ["/libexec"];
    localBinInPath = true;
  };

  hardware = {
    enableAllFirmware = true;
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    i2c.enable = true;
  };

  networking = {
    hostName = "nixos";
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  nix = {
    settings = {
      # hard link duplicates
      auto-optimise-store = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
    gc = {
      automatic = true;
      dates = "daily";
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit pkgs;
      inherit inputs;
    };
    users.francois = {
      imports = [
        ./home.nix
      ];
    };
  };

  powerManagement = {
    enable = true;
    powertop.enable = true;
  };

  programs = {
    # java = {
    #   enable = true;
    #   package = pkgs.jdk17;
    # };

    nix-ld.enable = true;
    mtr.enable = true;
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    auto-cpufreq = {
      enable = true;
      settings = {
        battery = {
          governor = "powersave";
          turbo = "never";
        };
        charger = {
          governor = "performance";
          turbo = "auto";
        };
      };
    };
  };

  security = {
    sudo = {
      enable = true;
      extraRules = [
        {
          groups = ["wheel"];
          commands = [
            {
              command = "/run/current-system/sw/bin/true";
              options = [
                "NOLOG_INPUT"
                "NOLOG_OUTPUT"
              ];
            }
          ];
        }
      ];
    };
    polkit.enable = true;
    acme = {
      acceptTerms = true;
      defaults.email = "francoisdprob@gmail.com";
    };
  };

  services = {
    logind = {
      killUserProcesses = true;
      powerKey = "lock";
      powerKeyLongPress = "reboot";
      lidSwitch = "lock";
      lidSwitchExternalPower = "ignore";
      lidSwitchDocked = "ignore";
    };
    solaar = {
      enable = true;
      package = pkgs.solaar;
    };
    envfs.enable = true;
    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
    };

    # postgresql = {
    #   enable = false;
    #   ensureDatabases = ["mydatabase"];
    #   authentication = pkgs.lib.mkOverride 10 ''
    #     #type database  DBuser  auth-method
    #     local all       all     trust
    #
    #     # ipv4
    #     host  all      all     127.0.0.1/32   trust
    #
    #     # ipv6
    #     host all       all     ::1/128        trust
    #   '';
    # };

    # File mounting
    udisks2.enable = true;
    devmon.enable = true;

    flatpak.enable = true;
    blueman.enable = true;
    openssh.enable = true;

    # Power
    upower.enable = true;
    thermald.enable = true;
    system76-scheduler.settings.cfsProfiles.enable = true;

    dbus = {
      enable = true;
      implementation = "broker";
    };
  };

  system = {
    stateVersion = "24.05";
  };

  time.timeZone = "Africa/Johannesburg";

  users.users.francois = {
    isNormalUser = true;
    description = "Francois Robbertze";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "lp"
      "scanner"
      "storage"
    ];
    shell = pkgs.fish;
  };
}
