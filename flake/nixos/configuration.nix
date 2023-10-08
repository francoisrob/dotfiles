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


  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
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

  # Configure console keymap
  console = {  
    keyMap = "us";
    font = "Lat2-Terminus16";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    defaultUserShell = pkgs.fish;
    users.francois = {
      isNormalUser = true;
      description = "Francois";
      extraGroups = [ "networkmanager" "wheel" "video" "audio" "lp" "scanner" "storage"];
      # packages = with pkgs; [];
    };
  };

  xdg.portal = {
    enable = true;
    # wlr.enable = true;
    # extraPortals = with pkgs; [ 
      # xdg-desktop-portal-wlr
      # xdg-desktop-portal-gtk
      # xdg-desktop-portal-hyprland
    # ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
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
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      git
      firefox
      dunst
      udiskie
      libnotify
      unzip
      wget
      python3
      gcc
      ripgrep
      wayland
      cargo
      cliphist
      xclip
      stow
      killall
    ];

    # gnome.excludePackages = (with pkgs; [
    #   gnome-photos
    #   gnome-tour
    # ]) ++ (with pkgs.gnome; [
    #     cheese # webcam tool
    #     gnome-music
    #     gnome-terminal
    #     gedit # text editor
    #     epiphany # web browser
    #     geary # email reader
    #     evince # document viewer
    #     gnome-characters
    #     totem # video player
    #     tali # poker game
    #     iagno # go game
    #     hitori # sudoku game
    #     atomix # puzzle game
    # ]);

    # sessionVariables = {
    #   NIXOS_OZONE_WL = "1";
    # };
    pathsToLink = [ "/libexec" ];
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  programs = {
    mtr.enable = true;
    hyprland = {
      enable = true;
      enableNvidiaPatches = true;
      xwayland.enable = true;
    };
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
    opengl.enable = true;
    nvidia.modesetting.enable = true;
    pulseaudio = {
      enable = false;
      support32Bit = true;
    };
  };

  services.udisks2.enable = true;

  sound.enable = true;
  services = {
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
    stateVersion = "23.05"; # Did you read the comment?
  };
}
