{...}: {
  programs = {
    adb = {
      enable = true;
    };
  };

  users = {
    groups = {
      adbusers = {};
    };
  };
}
