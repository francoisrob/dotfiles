{
  inputs,
  tuning,
  ...
}: {
  nixpkgs.config = import ../nixpkgs-config.nix;

  nix = {
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    settings = {
      max-jobs = tuning.maxJobs;
      cores = tuning.buildCores;
      auto-optimise-store = true;
      substituters = [
        "https://nix-community.cachix.org"
        "https://neovim-nightly.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "neovim-nightly.cachix.org-1:feIoInHRevVEplgdZvQDjhp11kYASYCE2NGY9hNrwxY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      experimental-features = ["nix-command" "flakes"];
      download-buffer-size = 524288000;
      build-dir = "/nix/var/nix/builds";
    };
    gc = {
      automatic = true;
      dates = "weekly";
      randomizedDelaySec = "45min";
      options = "--delete-older-than 14d";
    };
    nixPath = ["nixpkgs=${inputs.nixpkgs}"];
  };

  systemd.tmpfiles.rules = ["d /nix/var/nix/builds 0755 root root -"];
}
