# NEEDS hardware accelaration
{
  pkgs,
  lib,
  ...
}: {
  nixpkgs = {
    config = {
      allowUnfreePredicate = pkg:
        builtins.elem (lib.getName pkg) [
          "steam"
          "steam-original"
          "steam-unwrapped"
          "steam-run"
        ];
    };
  };

  programs = {
    steam = {
      enable = true;
      package = pkgs.steam.override {
        extraPkgs = p:
          with p; [
            libgdiplus
            glxinfo
          ];
      };
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
      # remotePlay = {
      #   openFirewall = true;
      # };
      dedicatedServer = {
        openFirewall = true;
      };
    };
  };
}
