{inputs}: [
  (final: prev: {
    gruvbox-kvantum-medium = final.callPackage ./pkgs/gruvbox-kvantum-medium {};
    gruvbox-gtk-morhetz = final.callPackage ./pkgs/gruvbox-gtk-morhetz {};

    mpv = prev.mpv.override {
      scripts = [final.mpvScripts.webtorrent-mpv-hook];
    };

    lutris = prev.lutris.override {
      extraLibraries = pkgs: [
        final.findutils
      ];
      extraPkgs = pkgs: [];
    };

    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });

    # mongodb-compass 1.49.10 fails to build: its buildCommand calls the old-API
    # `wrapGAppsHook <program>`, but the 2026-06-15 nixpkgs hook rewrite made
    # wrapGAppsHook take no args and guard on $output (unset in a buildCommand),
    # which trips bash's "bad array subscript". Replace that one line with the
    # equivalent modern wrap. Drop this when upstream fixes the package.
    mongodb-compass = prev.mongodb-compass.overrideAttrs (old: {
      buildCommand =
        builtins.replaceStrings
        ["wrapGAppsHook $out/bin/mongodb-compass"]
        ["export prefix=$out\n    gappsWrapperArgsHook\n    wrapProgram $out/bin/mongodb-compass \"\${gappsWrapperArgs[@]}\""]
        old.buildCommand;
    });
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
