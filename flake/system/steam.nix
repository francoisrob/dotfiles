{
  inputs,
  pkgs,
  lib,
  ... # Other options, such as system.stateVersion, system.build, etc.
}: {
programs.steam = {
  enable = true;
  remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
  dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
};
hardware.opengl.driSupport32Bit = true; # Enables support for 32bit libs that steam uses
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];
  environment.systemPackages = with pkgs; [
    steam
    steam-original
    steam-run
  ];
}
