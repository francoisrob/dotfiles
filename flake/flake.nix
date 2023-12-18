{
  description = "francoisrob flake v2";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      overlays = [
        (final: prev: { nwg-displays = prev.nwg-displays.override { hyprlandSupport = true; }; })
        (final: _prev: {
          stable = import inputs.stable {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        })
        (final: prev: {
          steam = prev.steam.override ({ extraPkgs ? pkgs': [ ], ... }: {
            extraPkgs = pkgs': (extraPkgs pkgs') ++ (with pkgs'; [
              libgdiplus
            ]);
          });
        })
        (self: super: {
          mpv = super.mpv.override {
            scripts = [ self.mpvScripts.mpris ];
          };
        })
      ];
    in
    {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = overlays; }
            ./hosts/default/configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
