{gruvbox-gtk-theme}: let
  palette = {
    "#c14a4a" = "#cc241d";
    "#ea6962" = "#fb4934";
    "#ab62b1" = "#b16286";
    "#d386cd" = "#d3869b";
    "#45707a" = "#458588";
    "#7daea3" = "#83a598";
    "#4c7a5d" = "#689d6a";
    "#89b482" = "#8ec07c";
    "#6c782e" = "#98971a";
    "#a9b665" = "#b8bb26";
    "#b47109" = "#d79921";
    "#d8a657" = "#fabd2f";
    "#c35e0a" = "#d65d0e";
    "#e78a4e" = "#fe8019";

    "#282524" = "#282828";
    "#242220" = "#1d2021";
    "#211f1e" = "#1d2021";
    "#141617" = "#1d2021";
  };

  gtk2Palette = {
    "#F9F5D7" = "#fbf1c7";
    "#1D2021" = "#282828";
    "#7DAEA3" = "#8ec07c";
    "#80AA9E" = "#689d6a";
    "#D386CD" = "#d3869b";
  };

  mkSed = args: builtins.concatStringsSep " " (builtins.attrValues args);

  sedArgs = mkSed (builtins.mapAttrs (from: to: "-e 's/${from}/${to}/gI'") palette);

  gtk2SedArgs = mkSed (builtins.mapAttrs (from: to: "-e 's/${from}/${to}/gI'") gtk2Palette);

  gtkrcSedArgs = mkSed (
    builtins.mapAttrs (from: to: "-e '/sed -i/!s/${from}/${to}/gI'") palette
  );

  theme = "Gruvbox-Teal-Dark-Medium";
in
  (gruvbox-gtk-theme.override {
    colorVariants = ["dark"];
    sizeVariants = ["standard"];
    themeVariants = ["teal"];
    tweakVariants = ["medium"];
  })
  .overrideAttrs (old: {
    pname = "gruvbox-gtk-theme-morhetz";

    postPatch =
      (old.postPatch or "")
      + ''
        # GTK 3 and GTK 4: sassc compiles these from the palette at install
        # time, and every shade is derived from it with mix(), so this one file
        # recolors the whole stylesheet including hover and active states.
        sed -i ${sedArgs} themes/src/sass/_color-palette-medium.scss

        # GTK 2 is not built from sass; see gtk2Palette above for why it needs a
        # different map and why the tokens must be left alone.
        find themes/src/main/gtk-2.0 -type f -exec sed -i ${gtk2SedArgs} {} +
        sed -i ${gtkrcSedArgs} themes/gtkrc.sh

        # The gtk-3.0/gtk-4.0 assets carry no accent (verified: they are grey
        # and black only), but the cinnamon/gnome-shell toggle and checkbox
        # SVGs do. Neither desktop is installed, so this is only to stop the
        # package shipping two different gruvboxes.
        find themes/src/assets -name '*.svg' -exec sed -i ${sedArgs} {} +
      '';

    postInstall =
      (old.postInstall or "")
      + ''
        # Check the whole installed theme, not just the stylesheets: GTK 2 has
        # its own hardcoded palette and was missed by an earlier version of this
        # patch that only looked at the sass.
        for dead in 89b482 4c7a5d c14a4a ea6962 6c782e a9b665 b47109 d8a657 \
                    c35e0a e78a4e 45707a 7daea3 ab62b1 d386cd \
                    282524 242220 211f1e 141617; do
          if grep -rqi "#$dead" "$out/share/themes/${theme}"; then
            echo "ERROR: Material #$dead survived the recolor in:" >&2
            grep -rli "#$dead" "$out/share/themes/${theme}" >&2
            exit 1
          fi
        done

        # And the colors that should have replaced them must actually be there.
        for f in gtk-2.0/gtkrc gtk-3.0/gtk.css gtk-4.0/gtk.css; do
          for want in 8ec07c 282828; do
            if ! grep -qi "#$want" "$out/share/themes/${theme}/$f"; then
              echo "ERROR: morhetz #$want absent from $f" >&2
              exit 1
            fi
          done
        done
      '';
  })
