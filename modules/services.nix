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

    flatpak.enable = true;
  };
}
