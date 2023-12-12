{
  inputs,
  pkgs,
  ...
}: {
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  services = {
    xserver = {
        enable = true;
        excludePackages = with pkgs; [
          xterm
        ];
        libinput = {
          enable = true;
        };
    };
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          # command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd Hyprland";
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
          user = "francois";
        };
        default_session = initial_session;
      };
    };
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      config.common.default = "gtk";
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };
  };
}
