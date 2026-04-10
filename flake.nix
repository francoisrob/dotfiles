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
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs = {
        hyprland = {
          follows = "hyprland";
        };
      };
    };
    hypr-dynamic-cursors = {
      url = "github:VirtCode/hypr-dynamic-cursors";
      inputs = {
        hyprland = {
          follows = "hyprland";
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

    nixosConfig = nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit inputs user hostName;
      };
      modules = [
        {nixpkgs.overlays = overlays;}
        inputs.hyprland.nixosModules.default
        home-manager.nixosModules.home-manager
        solaar.nixosModules.default
        nix-index-database.nixosModules.nix-index
        ./hosts/default/configuration.nix
      ];
    };
  in {
    devShells.${system} = import ./devshells {inherit inputs; pkgs = nixosConfig.pkgs;};

    nixosConfigurations.${hostName} = nixosConfig;

    checks.${system} = {
      nixos = nixosConfig.config.system.build.toplevel;
    };
  };
}
