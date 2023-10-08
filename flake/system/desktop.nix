{ pkgs, ... }:
{
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
    desktopManager = {
      xterm.enable = false;
      # gnome.enable = true;
    };
    windowManager = {
      # i3 = {
      #   enable = true;
      #   extraPackages = with pkgs; [
      #     dmenu #application launcher most people use
      #     i3status # gives you the default i3 status bar
      #     i3lock #default i3 screen locker
      #     i3blocks #if you are planning on using i3blocks over i3status
      #     ];
      #   };
      awesome = {
        enable = true;
        luaModules = with pkgs.luaPackages; [
          luarocks # is the package manager for Lua modules
          luadbi-mysql # Database abstraction layer
          ];
        };
    };
  };
  environment.systemPackages = [ ];
}
