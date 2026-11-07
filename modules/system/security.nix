{...}: let
  nopasswd = command: {
    command = "/run/current-system/sw/bin/systemctl ${command}";
    options = ["NOPASSWD"];
  };
in {
  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults!/run/current-system/sw/bin/true !syslog
      '';
      extraRules = [
        {
          groups = ["wheel"];
          commands = map nopasswd [
            "start mongodb"
            "stop mongodb"
            "start teamviewerd"
            "stop teamviewerd"
          ];
        }
      ];
    };
    polkit.enable = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
