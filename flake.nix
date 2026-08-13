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
    # Anthropic ships no Linux build; this repackages the official .deb.
    # Since its v3.0 the flake exposes only packages + overlays.default (no
    # NixOS module), so it is wired in as an overlay in modules/overlays.nix.
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
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
    inherit (nixpkgs) lib;

    system = "x86_64-linux";
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

    # Per-host tuning. Everything here is a function of the MACHINE -- thread
    # count, RAM size, and the memory-pressure thresholds derived from them --
    # rather than of taste. Taste-level settings stay in the shared modules so
    # both hosts keep behaving the same way.
    #
    # The attribute name is also the hostname, so `nixos-rebuild switch
    # --flake .` resolves the right config by hostname on each machine. There
    # is deliberately no "nixos" alias: a stale hostname then fails loudly with
    # "attribute not found" instead of silently building the other host's
    # config (which would mean nvidia + intel + a LUKS UUID that isn't there).
    hosts = {
      # i7-1165G7, 4c/8t, 16G RAM, LUKS root, Intel iGPU + NVIDIA MX350
      laptop = {
        maxJobs = 4;
        buildCores = 2;
        zramPercent = 50;
        swapFileSize = 8 * 1024;
        earlyoomMemThreshold = 15;
        earlyoomMemKillThreshold = 5;
      };

      # Ryzen AI 9 HX 370, 12c/24t, 32G RAM (~27G visible after the iGPU
      # carve-out), no encryption, Radeon 890M iGPU only.
      minipc = {
        # Same rule as the laptop: jobs x cores == thread count, so builds can
        # saturate the box but never oversubscribe it. nix.daemonCPUSchedPolicy
        # is "idle" in boot.nix, so the desktop still preempts builds.
        maxJobs = 6;
        buildCores = 4;
        # 25% of 27G is the same ~7G device the laptop gets from 50% of 16G.
        # memoryPercent is the zram device's UNCOMPRESSED capacity, not the RAM
        # it consumes -- actual footprint is that divided by the zstd ratio.
        zramPercent = 25;
        swapFileSize = 8 * 1024;
        # 10% of 27G is ~2.7G, matching the laptop's 15%-of-16G in absolute
        # terms. earlyoom thresholds are percentages, so they need rescaling
        # when RAM changes or they fire far too early.
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
          solaar.nixosModules.default
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

    # Keyed "user@host" so `home-manager switch --flake .` resolves by
    # $USER@$HOSTNAME without needing an explicit attribute on either machine.
    homeConfigurations =
      lib.mapAttrs'
      (hostName: cfg: lib.nameValuePair "${user}@${hostName}" cfg)
      homeConfigs;

    # The pinned home-manager CLI, so `make home` works even before the
    # first activation puts programs.home-manager on PATH.
    packages.${system} = {
      home-manager = home-manager.packages.${system}.default;
    };

    # `nix flake check` builds every host, so a change that breaks the machine
    # you are NOT sitting at still fails here.
    checks.${system} =
      (lib.mapAttrs'
        (n: c: lib.nameValuePair "nixos-${n}" c.config.system.build.toplevel)
        nixosConfigs)
      // (lib.mapAttrs'
        (n: c: lib.nameValuePair "home-${n}" c.activationPackage)
        homeConfigs);
  };
}
