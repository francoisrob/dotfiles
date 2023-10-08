{ pkgs, lib, ... }:
# let
#   xsession-name = "Hyprland";
# in
{
  services.xserver = {
    enable = true;
    libinput = {
      enable = true;
      touchpad.disableWhileTyping = true;
    };
    layout = "us";
    xkbVariant = "";
    displayManager = {
      # autoLogin.enable = true;
      # autoLogin.user = "francois";
      # defaultSession = xsession-name;
      lightdm = {
        enable = true;
        # greeter.enable = false;
      };
    };
    desktopManager = {
      xterm.enable = false;
      gnome.enable = false;
      # session = [
      #   {
      #     name = xsession-name;
      #     start = ''
      #       ${pkgs.runtimeShell} $HOME/.hm-xsession &
      #       waitPID=$!
      #     '';
      #   }
      # ];
    };
    windowManager = {
      i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu #application launcher most people use
          i3status # gives you the default i3 status bar
          i3lock #default i3 screen locker
          i3blocks #if you are planning on using i3blocks over i3status
        ];
      };
    };
  };
  environment.systemPackages = [ ];
  programs.seahorse.enable = true;
}
    # xserver = {
    #   layout = "us";
    #   xkbVariant = "";
    #   displayManager = {
    #     lightdm.enable = true;
    #     defaultSession = "xfce";
    #   };
    # };
