{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["ntfs"];
  };
  console = {
    keyMap = "us";
    font = "Lat2-Terminus16";
  };
  environment = {
    systemPackages = with pkgs; [
      wayland
      vim
      libnotify
      unzip
      zip
      wget
      stow
      killall
      gnumake
      glxinfo

      brightnessctl
      python3
      gcc
      cargo
      ripgrep
      pavucontrol
      mpv

      noto-fonts
      (callPackage ../../configs/sddm-catppuccin.nix {}).catppuccin-flavour
    ];
    pathsToLink = ["/libexec"];
    localBinInPath = true;
  };
  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      (nerdfonts.override {fonts = ["JetBrainsMono" "DroidSansMono"];})
    ];
  };
  hardware = {
    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
      ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    # https://discourse.nixos.org/t/how-to-enable-ddc-brightness-control-i2c-permissions/20800/11
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
  i18n.defaultLocale = "en_US.UTF-8";
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
  nixpkgs = {
    config = {
      allowUnfree = true;
      firefox = {
        enableGoogleTalkPlugin = true;
        enableAdobeFlash = true;
      };
      packageOverrides = pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
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
  programs = {
    nix-ld.enable = true;
    mtr.enable = true;
    neovim = {
      viAlias = true;
      vimAlias = true;
      enable = true;
      defaultEditor = true;
    };
    fish.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
  };
  security = {
    polkit.enable = true;
    rtkit.enable = true;
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
    dbus = {
      enable = true;
      packages = with pkgs; [blueman];
    };
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
  time.timeZone = "Africa/Johannesburg";
  users.users.francois = {
    isNormalUser = true;
    description = "Francois";
    extraGroups = ["networkmanager" "wheel" "video" "audio" "lp" "scanner" "storage"];
    shell = pkgs.fish;
  };
}
