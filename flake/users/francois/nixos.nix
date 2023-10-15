{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["ntfs"];
  };

  networking = {
    hostName = "nixos";
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_US.UTF-8";

  console = {
    keyMap = "us";
    font = "Lat2-Terminus16";
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      firefox = {
        enableGoogleTalkPlugin = true;
        enableAdobeFlash = true;
      };
    };
    overlays = [
      (self: super: {
        mpv = super.mpv.override {
          scripts = [self.mpvScripts.mpris];
        };
      })
    ];
  };

  environment.localBinInPath = true;

  nix = {
    settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      wayland
      vim
      libnotify
      unzip
      wget
      stow
      killall
      gnumake

      python3
      gcc
      cargo
      ripgrep
      pavucontrol
      mpv

      firefox
      chromium
      noto-fonts
      (callPackage ../../configs/sddm-catppuccin.nix {}).catppuccin-flavour
    ];
    pathsToLink = ["/libexec"];
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override {fonts = ["JetBrainsMono" "DroidSansMono"];})
    ];
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  programs = {
    nix-ld.enable = true;
    mtr.enable = true;

    neovim = {
      enable = true;
      defaultEditor = true;
    };
    light.enable = true;
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };

  sound.enable = true;
  services = {
    # File mounting
    gvfs.enable = true;
    udisks2.enable = true;
    devmon.enable = true;

    flatpak.enable = true;
    blueman.enable = true;
    openssh.enable = true;
    dbus.enable = true;
    pipewire = {
      enable = true;
      audio.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channel/nixos-unstable";
    };
    stateVersion = "23.05";
  };

  users.users.francois = {
    isNormalUser = true;
    description = "Francois";
    extraGroups = ["networkmanager" "wheel" "video" "audio" "lp" "scanner" "storage"];
    shell = pkgs.fish;
  };
}
