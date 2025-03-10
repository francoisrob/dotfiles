{pkgs, ...}: {
  services = {
    solaar = {
      enable = true;
      package = pkgs.solaar;
    };

    mongodb = {
      enable = true;
      package = pkgs.mongodb-ce;
    };

    # Screenshare fixed for slack desktop
    # flatpak.enable = true;
  };
}
