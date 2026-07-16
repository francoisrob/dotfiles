{pkgs, ...}: let
  # Gruvbox Dark, medium contrast (bg0 = #282828)
  # Palette: https://github.com/morhetz/gruvbox
  gruvboxColors = [
    "282828" # Black (bg0)
    "cc241d" # Red
    "98971a" # Green
    "d79921" # Yellow
    "458588" # Blue
    "b16286" # Magenta
    "689d6a" # Cyan
    "a89984" # White
    "928374" # Bright Black
    "fb4934" # Bright Red
    "b8bb26" # Bright Green
    "fabd2f" # Bright Yellow
    "83a598" # Bright Blue
    "d3869b" # Bright Magenta
    "8ec07c" # Bright Cyan
    "ebdbb2" # Bright White
  ];
in {
  console = {
    enable = true;
    keyMap = "us";
    font = "ter-132n";
    packages = with pkgs; [terminus_font];
    colors = gruvboxColors;
    earlySetup = true;
  };

  fonts = {
    enableGhostscriptFonts = true;
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      font-awesome
      corefonts
      noto-fonts
      joypixels
      ubuntu-sans
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = ["Noto Sans"];
        monospace = ["JetBrainsMono Nerd Font"];
      };
    };
    fontDir = {
      enable = true;
    };
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LANGUAGE = "en_US";
      LC_MESSAGES = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
      LC_CTYPE = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
    };
  };

  nixpkgs = {
    config = {
      joypixels = {
        acceptLicense = true;
      };
    };
  };
}
