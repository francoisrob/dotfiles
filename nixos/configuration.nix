{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";

  # console = {
  #  font = "Lat2-Terminus16";
  #  keyMap = "us";
  #  useXkbConfig = true;
  #};

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11.
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  sound.enable = true;
  # hardware.pulseaudio.enable = true;

  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.users.francois = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      tree
    ];
  };

  # To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
	wayland  
	vim
	kitty
	git
  ];

  programs.hyprland = {
   enable = true;
   nvidiaPatches = true;
   xwayland.enable = true;
  };

  hardware = {
    opengl.enable = true;
    nvidia.modesetting.enable = true;
  };

  environment.sessionVariables = {
     WLR_NO_HARDWARE_CURSORS ="1";
     NIXOS_OZONE_WL = "1";
  };

  # List services that you want to enable:
  services.pipewire = {
	enable = true;
	alsa.enable = true;
	alsa.support32Bit = true;
	pulse.enable = true;
	jack.enable = true;
  };

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  security.polkit.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # DNC
  system.stateVersion = "23.05";
}

