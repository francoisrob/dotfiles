{
  description = "francoisrob nixos flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    home-manager = {
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
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    grok-bot = {
      url = "github:jordangarrison/grok-bot-flake";
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
    nix-index-database,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    system = "x86_64-linux";
    user = "francois";

    overlays = import ./modules/overlays.nix {inherit inputs;};

    pkgs = import nixpkgs {
      inherit system overlays;
      config = import ./modules/nixpkgs-config.nix;
    };

    hosts = {
      laptop = {
        maxJobs = 4;
        buildCores = 2;
        zramPercent = 50;
        swapFileSize = 8 * 1024;
        earlyoomMemThreshold = 15;
        earlyoomMemKillThreshold = 5;
      };

      minipc = {
        maxJobs = 6;
        buildCores = 4;
        zramPercent = 25;
        swapFileSize = 8 * 1024;
        earlyoomMemThreshold = 10;
        earlyoomMemKillThreshold = 4;
      };
    };

    mkNixos = hostName: tuning:
      lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs user hostName tuning;
        };
        modules = [
          {nixpkgs.overlays = overlays;}
          inputs.hyprland.nixosModules.default
          nix-index-database.nixosModules.nix-index
          ./hosts/${hostName}/configuration.nix
        ];
      };

    mkHome = hostName:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs user hostName;
        };
        modules = [
          ./home-manager
        ];
      };

    nixosConfigs = lib.mapAttrs mkNixos hosts;
    homeConfigs = lib.mapAttrs (hostName: _: mkHome hostName) hosts;
  in {
    formatter.${system} = nixpkgs.legacyPackages.${system}.alejandra;

    nixosConfigurations = nixosConfigs;

    homeConfigurations =
      lib.mapAttrs'
      (hostName: cfg: lib.nameValuePair "${user}@${hostName}" cfg)
      homeConfigs;

    packages.${system} = {
      home-manager = home-manager.packages.${system}.default;
    };

    checks.${system} =
      (lib.mapAttrs'
        (n: c: lib.nameValuePair "nixos-${n}" c.config.system.build.toplevel)
        nixosConfigs)
      // (lib.mapAttrs'
        (n: c: lib.nameValuePair "home-${n}" c.activationPackage)
        homeConfigs);
  };
}
