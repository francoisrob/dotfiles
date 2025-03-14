{
  pkgs,
  inputs,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit pkgs;
      inherit inputs;
    };
    users = {
      francois = {
        imports = [
          ../home-manager
        ];
      };
    };
  };
}
