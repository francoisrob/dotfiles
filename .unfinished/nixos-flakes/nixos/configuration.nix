{ config, pkgs, ... }:

let
  user = "francois";
in
{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      grub = {
        enable = true;
	device = "/dev/sda";
	configurationLimit = 5;
      };
      timeout = 5;
    };
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment = {
    systemPackages = with pkgs; [
      # waylan
        # firefoxd  
      vim
      git
      dunst
      unzip
      wget
      python3
      cargo
      rustc
      gcc
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "DroidSansMono" ]; })
  ];

  hardware = {
    opengl.enable = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_ZA.UTF-8";
      LC_MONETARY = "en_ZA.UTF-8";
    };
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
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
 #      (self: super: {
 #        discord = super.discord.overrideAttrs (
	#   _: { src = builtins.fetchTarball {
	#     url = "https://discord.com/api/download?platform=linux&format=tar.gz";
	#     sha256 = "09ianc37myki50g1404g0misd6qnk9pbiq8cx5cyvndwxz5gnlm7";
	#   }; }
	# );
 #      })
    ];
  };
  
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    light.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    zsh = {
      enable = true;
      shellAliases = {
        ll = "ls -l";
        update = "sudo nixos-rebuild switch";
      };
      autosuggestions.enable = true;
    };
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };
  
  services = {
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
    xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
	defaultSession = "hyprland";
      };
    };
  };

  sound.enable = true;

  system = {
    autoUpgrade = {
      enable = true;
      channel = "https://nixos.org/channel/nixos-unstable";
    };
    stateVersion = "23.05";
  };

  time.timeZone = "Africa/Johannesburg";

  users = {
    defaultUserShell = pkgs.zsh;
    users.${user} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "networkmanager" "lp" "scanner"];
      packages = with pkgs; [
        neofetch
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}

