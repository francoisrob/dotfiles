{inputs}: [
  (final: prev: {
    mpv = prev.mpv.override {
      scripts = [final.mpvScripts.webtorrent-mpv-hook];
    };

    lutris = prev.lutris.override {
      extraLibraries = pkgs: [
        final.findutils
      ];
      extraPkgs = pkgs: [];
    };
  })

  inputs.neovim-nightly.overlays.default

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
