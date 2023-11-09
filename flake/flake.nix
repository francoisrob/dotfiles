{
  description = "Frannas Flakkas";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stable.url = "github:nixos/nixpkgs/nixos-23.05";
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

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    overlays = [
      (final: prev: {nerdfonts = prev.nerdfonts.override {fonts = ["JetBrainsMono"];};})
      (final: prev: {nwg-displays = prev.nwg-displays.override {hyprlandSupport = true;};})
      (final: _prev: {
        stable = import inputs.stable {
          system = final.system;
          config.allowunfree = true;
        };
      })
    ];
    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.dell-intel = mkSystem "dell-intel" {
      system = "x86_64-linux";
      user = "francois";
    };
  };
}
