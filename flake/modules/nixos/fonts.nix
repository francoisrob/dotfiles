{ pkgs, ... }: {
  console = {
    colors = [
      "191724"
      "31748f"
      "9ccfd8"
      "f6c177"
      "31748f"
      "c4a7e7"
      "9ccfd8"
      "524f67"
      "403d52"
      "eb6f92"
      "31748f"
      "f6c177"
      "9ccfd8"
      "c4a7e7"
      "9ccfd8"
      "e0def4"
    ];
    keyMap = "us";
    enable = true;
    earlySetup = true;
    packages = with pkgs; [ terminus_font ];
    font = "${pkgs.terminus_font}/share/consolefonts/ter-132n.psf.gz";
  };

  fonts = {
    enableGhostscriptFonts = true;
    enableDefaultPackages = true;
    fontconfig.enable = true;
    fontDir.enable = true;
    packages = with pkgs; [
      font-awesome
      corefonts
      noto-fonts
      joypixels
      ubuntu_font_family
    ];
  };

  nixpkgs.config.joypixels.acceptLicense = true;
}
