{pkgs, ...}: {
  imports = [
    ./c.nix
    ./flutter.nix
    ./golang.nix
    ./lua.nix
    ./nix.nix
    ./python.nix
    ./rust.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      nix-index
    ];
  };
}
