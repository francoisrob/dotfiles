{ pkgs, lib, ... }:
let
  xsession-name = "i3";
in
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
      autoLogin.enable = true;
      autoLogin.user = "francois";
      defaultSession = xsession-name;
      lightdm = {
        enable = true;
        greeter.enable = false;
      };
    };
    desktopManager = {
      session = [
        {
          name = xsession-name;
          start = ''
            ${pkgs.runtimeShell} $HOME/.hm-xsession &
            waitPID=$!
          '';
        }
      ];
    };
    windowManager = {
      i3 = {
        enable = true;
      };
    };
  };
  environment.systemPackages = [ ];
  programs.seahorse.enable = true;
}

