{ pkgs, ... }:
let
  tuigreet = "${pkgs.greetd.tuigreet}/bin/tuigreet";
in
{
  programs = {
    uwsm.enable = true;
    seahorse.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };
  };

  services = {
    xserver = {
      enable = true;
      excludePackages = with pkgs; [
        xterm
      ];
    };

    gnome.gnome-keyring.enable = true;
    libinput = {
      enable = true;
    };

    greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${tuigreet} -r -t --asterisks --cmd 'uwsm start -S hyprland-uwsm.desktop'";
          user = "francois";
        };
      };
    };

  };

  xdg = {
    mime.enable = true;
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-kde
      ];
    };
  };

  security = {
    pam = {
      services.greetd.enableGnomeKeyring = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      libsecret
      hyprpolkitagent

      wayland # Needed for Hyprland
      libnotify # Needed for dunst
      rofi-wayland
    ];
    # libsecret api needed

    # etc."greetd/hyprland.conf".text = ''
    #   exec-once = qtgreet; hyprctl dispatch exit
    # '';

  };
}
