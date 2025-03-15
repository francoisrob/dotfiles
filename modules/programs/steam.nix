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
    overlays = [
      (final: prev: {
        steam = prev.steam.override (
          {extraPkgs ? pkgs': [], ...}: {
            extraPkgs = pkgs':
              (extraPkgs pkgs')
              ++ (with pkgs'; [
                libgdiplus
                glxinfo
              ]);
          }
        );
      })
    ];
  };

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
