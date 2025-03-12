{
  description = "francoisrob flake v2";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=nixos-unstable";
    };
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-24.11";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    solaar = {
      url = "github:Svenum/Solaar-Flake/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    waybar = {
      url = "github:Alexays/Waybar/master";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    solaar,
    auto-cpufreq,
    nur,
    ...
  }: let
    system = "x86_64-linux";
    overlays = [
      (final: prev: {
        stable = import nixpkgs-stable {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      })
      (final: prev: {
        steam = prev.steam.override (
          {extraPkgs ? pkgs': [], ...}: {
            extraPkgs = pkgs':
              (extraPkgs pkgs')
              ++ (with pkgs'; [
                libgdiplus
              ]);
          }
        );
      })
      (self: super: {
        mpv = super.mpv.override {
          scripts = [self.mpvScripts.mpris];
        };
      })
      (final: prev: {
        waybar_git = prev.waybar.overrideAttrs (oldAttrs: {
          src = inputs.waybar;
        });
      })
      (final: prev: {
        nur = import nur;
      })
    ];
  in {
    devShells.${system} = let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          jdk
        ];
      };
      jdk17 = pkgs.mkShell {
        buildInputs = with pkgs; [
          jdk17
        ];
      };
    };

    nixosConfigurations = {
      inspiron-7400 = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          {nixpkgs.overlays = overlays;}
          home-manager.nixosModules.home-manager
          solaar.nixosModules.default
          auto-cpufreq.nixosModules.default
          ./hosts/inspiron_7400/configuration.nix
        ];
      };
    };
  };
}
