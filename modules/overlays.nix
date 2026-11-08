{inputs}: [
  (final: prev: {
    gruvbox-kvantum-medium = final.callPackage ./pkgs/gruvbox-kvantum-medium {};
    gruvbox-gtk-theme = final.callPackage ./pkgs/gruvbox-gtk-theme {};
    gruvbox-gtk-morhetz = final.callPackage ./pkgs/gruvbox-gtk-morhetz {};

    mpv = prev.mpv.override {
      scripts = with final.mpvScripts; [
        webtorrent-mpv-hook
        uosc
        thumbfast
        mpris
      ];
    };

    lutris = prev.lutris.override {
      extraLibraries = pkgs: [
        final.findutils
      ];
      extraPkgs = pkgs: [];
    };
  })

  inputs.neovim-nightly.overlays.default

  inputs.claude-desktop.overlays.default

  inputs.grok-bot.overlays.default

  (final: prev: {
    libvirt = prev.libvirt.override {
      enableXen = false;
      enableGlusterfs = false;
      enableIscsi = false;
    };
  })

  (final: prev: {
    steam = prev.steam.override (
      {extraPkgs ? pkgs': [], ...}: {
        extraPkgs = pkgs':
          (extraPkgs pkgs')
          ++ (with pkgs'; [
            libgdiplus
          ]);
      }
    );
  })
]
