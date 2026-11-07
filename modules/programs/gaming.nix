{
  pkgs,
  user,
  ...
}: {
  programs = {
    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;
          inhibit_screensaver = 1;
        };
        custom = {
          start = "${pkgs.bash}/bin/bash /home/${user}/.config/hypr/scripts/gaming-mode.sh on";
          end = "${pkgs.bash}/bin/bash /home/${user}/.config/hypr/scripts/gaming-mode.sh off";
        };
      };
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };

  environment.systemPackages = with pkgs; [
    mangohud
  ];
}
