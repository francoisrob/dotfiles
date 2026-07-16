{
  description = "francoisrob nixos flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    home-manager = {
      # master tracks nixos-unstable; home-manager has no separate unstable branch
      url = "github:nix-community/home-manager/master";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    solaar = {
      url = "github:Svenum/Solaar-Flake/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    solaar,
    nix-index-database,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    hostName = "nixos";
    user = "francois";

    overlays = import ./modules/overlays.nix {inherit inputs;};

    # Home-manager is standalone, so it builds its own package set. Same
    # overlays and nixpkgs config as the system (modules/system/boot.nix
    # imports the same file), so user packages see the identical nixpkgs
    # they did under the NixOS module.
    pkgs = import nixpkgs {
      inherit system overlays;
      config = import ./modules/nixpkgs-config.nix;
    };

    nixosConfig = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs user hostName;
      };
      modules = [
        {nixpkgs.overlays = overlays;}
        inputs.hyprland.nixosModules.default
        solaar.nixosModules.default
        nix-index-database.nixosModules.nix-index
        ./hosts/default/configuration.nix
      ];
    };

    homeConfig = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit inputs user;
      };
      modules = [
        ./home-manager
      ];
    };
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations.${hostName} = nixosConfig;
    homeConfigurations.${user} = homeConfig;

    # The pinned home-manager CLI, so `make home` works even before the
    # first activation puts programs.home-manager on PATH.
    packages.${system} = {
      home-manager = home-manager.packages.${system}.default;
    };

    checks.${system} = {
      nixos = nixosConfig.config.system.build.toplevel;
      home = homeConfig.activationPackage;
    };
  };
}
