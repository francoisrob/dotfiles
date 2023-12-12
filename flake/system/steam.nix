# NEEDS hardware accelaration
{ pkgs, lib, ...}:
{
  environment.systemPackages = with pkgs; [
    steam
    steam-run
  ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
}
