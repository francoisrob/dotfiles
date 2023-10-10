{ pkgs, ... }:
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = [ "ntfs" ];
  };

  networking = {
    hostName = "nixos"; # Define your hostname.
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

  users = {
    defaultUserShell = pkgs.fish;
    users.francois = {
      isNormalUser = true;
      description = "Francois";
      extraGroups = [ "networkmanager" "wheel" "video" "audio" "lp" "scanner" "storage"];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-wlr ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    firefox = {
      enableGoogleTalkPlugin = true;
      enableAdobeFlash = true;
    };
  };

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
      git
      udiskie
      libnotify
      unzip
      wget
      stow
      killall

      python3
      gcc
      cargo
      ripgrep
      pavucontrol

      firefox
      chromium
    ];
    pathsToLink = [ "/libexec" ];
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
    opengl.enable = true;
  };

  sound.enable = true;
  services = {
    udisks2.enable = true;
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
}
