{
  nixpkgs,
  overlays,
  inputs,
}: name: {
  system,
  user,
}: let
  machineConfig = ../machines/${name}.nix;
  hardwareConfig = ../machines/hardware/${name}.nix;

  userOSConfig = ../users/${user}/nixos.nix;
  userHMConfig = ../users/${user}/home-manager.nix;
  userConfig = ../users/${user}/configuration.nix;

  systemFunc = nixpkgs.lib.nixosSystem;
  home-manager = inputs.home-manager.nixosModules;
in
  systemFunc rec {
    inherit system;

    modules = [
      {nixpkgs.overlays = overlays;}
      machineConfig
      hardwareConfig

      userOSConfig
      userConfig

      home-manager.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = import userHMConfig {
          inputs = inputs;
        };
      }
      {
        config._module.args = {
          currentSystem = system;
          currentSystemName = name;
          currentSystemUser = user;
          inputs = inputs;
        };
      }
    ];
  }
