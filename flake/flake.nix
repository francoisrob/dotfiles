{
  description = "francoisrob flake v2";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-snapd = {
    #   url = "github:nix-community/nix-snapd";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      # nix-snapd,
      ...
    }:
    let
      system = "x86_64-linux";
      overlays = [
        # (final: prev: { nwg-displays = prev.nwg-displays.override { hyprlandSupport = true; }; })
        (final: _prev: {
          stable = import inputs.stable {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
        })
        (final: prev: {
          steam = prev.steam.override (
            {
              extraPkgs ? pkgs': [ ],
              ...
            }:
            {
              extraPkgs =
                pkgs':
                (extraPkgs pkgs')
                ++ (with pkgs'; [
                  libgdiplus
                ]);
            }
          );
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
        inspiron-7400 = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = overlays; }
            # nix-snapd.nixosModules.default
            home-manager.nixosModules.home-manager
            ./hosts/inspiron_7400/configuration.nix
          ];
        };
      };
    };
}
