{pkgs, ...}: let
  gruvboxColors = [
    "282828"
    "cc241d"
    "98971a"
    "d79921"
    "458588"
    "b16286"
    "689d6a"
    "a89984"
    "928374"
    "fb4934"
    "b8bb26"
    "fabd2f"
    "83a598"
    "d3869b"
    "8ec07c"
    "ebdbb2"
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
      LC_NUMERIC = "C";
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
