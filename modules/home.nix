{
  inputs,
  user,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs;
      inherit user;
    };
    users = {
      ${user} = {
        imports = [
          ../home-manager
        ];
      };
    };
  };
}
