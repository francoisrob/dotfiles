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
    solaar = {
      url = "github:Svenum/Solaar-Flake/main";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    waybar = {
      url = "github:Alexays/Waybar/master";
    };
    nurpkgs = {
      url = "github:nix-community/NUR";
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
    };
    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
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

    tagstudio = {
      url = "github:TagStudioDev/TagStudio/Alpha-v9.5.3";
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
    auto-cpufreq,
    nurpkgs,
    nix-index-database,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    hostName = "nixos";
    user = "francois";

    overlays = [
      nurpkgs.overlays.default
    ];

    pkgs = import nixpkgs {
      inherit system;
      inherit overlays;
    };

    devshells = import ./devshells {
      inherit inputs;
      inherit pkgs;
    };
  in {
    devShells.${system} = devshells;
    # devShells.${system} = let
    #   pkgs = nixpkgs.legacyPackages.${system};
    # in {
    #   default = pkgs.mkShell {
    #     buildInputs = with pkgs; [
    #       jdk
    #     ];
    #   };
    #   jdk17 = pkgs.mkShell {
    #     buildInputs = with pkgs; [
    #       jdk17
    #     ];
    #   };
    # };

    nixosConfigurations = {
      ${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit user;
          inherit hostName;
        };
        modules = [
          {nixpkgs.overlays = overlays;}
          home-manager.nixosModules.home-manager
          solaar.nixosModules.default
          auto-cpufreq.nixosModules.default
          nix-index-database.nixosModules.nix-index
          ./hosts/default/configuration.nix
        ];
      };
    };
  };
}
