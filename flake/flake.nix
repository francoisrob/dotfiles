{
  description = "Frannas Flakkas";

  inputs = {
    devenv.url = "github:cachix/devenv/latest";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      # pkgs = import nixpkgs {
      #   inherit system;
      #   config.allowUnfree = true;
      # };
      overlays = {
        unstable = import nixpkgs-unstable {
          system = system;
          config.allowUnfree = true;
        };
      };
    in {
      nixosConfigurations = {
        francois = lib.nixosSystem {
          system = system;
          modules = [
            {
              nix = {
                registry = {
                  nixpkgs.flake = nixpkgs-unstable;
                };
              };
              nixpkgs.overlays = [ (_: _: overlays) ];
            }
            nixpkgs.nixosModules.notDetected

            ./nixos/hardware-configuration.nix
            ./nixos/configuration.nix

            ./configuration.nix

            hyprland.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "home-manager-backup";
                  users.francois = import ./home/home.nix ;
                  extraSpecialArgs = {
                      isNvidia = true;
                      inherit hyprland;
                      inherit inputs;
                    };
                };
            }
          ];
        }; 
      };
    };
}
