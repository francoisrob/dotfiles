{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    android-tools
  ];

  users = {
    groups = {
      adbusers = {};
    };
  };
}
