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
    # defaultLocale sets LANG, and every unset LC_* category falls back to it,
    # so restating en_US.UTF-8 per category buys nothing. LC_ALL in particular
    # was actively harmful: it outranks every other LC_* variable, so nothing
    # downstream could override a category. That made LC_NUMERIC permanently
    # en_US.UTF-8, and libmpv refuses to initialise unless it is "C" (it
    # returns NULL from mpv_create()), which crashed stremio on startup.
    #
    # LC_NUMERIC = "C" only drops thousands grouping (1234567 rather than
    # 1,234,567); the decimal separator is "." under both C and en_US.
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
