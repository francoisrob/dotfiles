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
    colors = catppuccinColors;
    earlySetup = true;
    packages = with pkgs; [terminus_font];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
  };

  fonts = {
    enableGhostscriptFonts = true;
    enableDefaultPackages = true;
    fontconfig.enable = true;
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts._0xproto
      font-awesome
      corefonts
      noto-fonts
      joypixels
      ubuntu_font_family
    ];
  };

  nixpkgs.config.joypixels.acceptLicense = true;
}
