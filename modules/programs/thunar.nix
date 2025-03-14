{pkgs, ...}: {
  services = {
    tumbler = {
      enable = true;
    };
    gvfs = {
      enable = true;
    };
  };

  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
        thunar-media-tags-plugin
      ];
    };
  };

  environment = {
    systemPackages = with pkgs; [
      file-roller # Needed for zip
    ];
  };
}
