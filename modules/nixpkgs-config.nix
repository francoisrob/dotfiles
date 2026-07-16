# Shared nixpkgs config: the NixOS system imports it (modules/system/boot.nix)
# and flake.nix feeds it to the standalone home-manager package set, so the
# two can never drift apart.
{
  allowUnfree = true;
  # Electron 39 is EOL upstream but still pulled in by Electron-based
  # desktop apps (slack, discord, mongodb-compass, etc.). Allow it until
  # those packages bump to a supported Electron. Re-checked 2026-06-13:
  # still required on nixos-unstable.
  permittedInsecurePackages = [
    "electron-39.8.10"
  ];
}
