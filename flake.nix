{
  description = "francoisrob nixos flake";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    flutter-nixpkgs = {
      url = "github:NixOS/nixpkgs/10069ef4cf863633f57238f179a0297de84bd8d3";
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
      url = "github:TagStudioDev/TagStudio";
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

      (final: prev: {
        mindustry = prev.mindustry.overrideAttrs (old: {
          version = "v153";
          src = prev.fetchFromGitHub {
            owner = "Anuken";
            repo = "Mindustry";
            rev = "v153";
            sha256 = "sha256-yVrOHZOCZrI5SsmMdo7Eh+zS0PXv2X67zLCdLOWcPVc=";
          };
        });
      })
    ];

    devshells = import ./devshells {
      inherit inputs;
      pkgs = import inputs.flutter-nixpkgs {
        inherit system;
      };
    };
  in {
    devShells.${system} = devshells;

    nixosConfigurations = {
      ${hostName} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit user;
          inherit hostName;
        };
        modules = [
          {
            nixpkgs = {
              overlays = overlays;
            };
          }
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
