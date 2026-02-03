# NEEDS hardware accelaration
{pkgs, ...}: {
  programs = {
    steam = {
      enable = true;
      package = pkgs.steam;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      dedicatedServer = {
        openFirewall = true;
      };
    };
  };
}
