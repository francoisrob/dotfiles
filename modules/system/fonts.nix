{pkgs, ...}: let
  catppuccinColors = [
    "1e1e2e" # Black (Base)
    "f38ba8" # Red
    "a6e3a1" # Green
    "f9e2af" # Yellow
    "89b4fa" # Blue
    "f5c2e7" # Magenta
    "94e2d5" # Cyan
    "cdd6f4" # White
    "45475a" # Bright Black
    "f38ba8" # Bright Red
    "a6e3a1" # Bright Green
    "f9e2af" # Bright Yellow
    "89b4fa" # Bright Blue
    "f5c2e7" # Bright Magenta
    "94e2d5" # Bright Cyan
    "b1b6c9" # Bright White
  ];
in {
  console = {
    enable = true;
    keyMap = "us";
    font = "ter-132n";
    packages = with pkgs; [terminus_font];
    # colors = catppuccinColors;
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
