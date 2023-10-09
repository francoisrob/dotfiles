{ ... }:
{
  programs = {
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };
  services.xserver = {
    enable = true;
    videoDrivers = [ "intel" ];
    deviceSection = ''
      Option "DRI" "3"
      Option "TearFree" "true"
      '';
    libinput = {
      enable = true;
      touchpad.disableWhileTyping = true;
      mouse.naturalScrolling = false;
    };
    layout = "us";
    xkbVariant = "";
    displayManager = {
      lightdm = {
        enable = true;
        };
    };
  };
}
