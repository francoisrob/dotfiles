{gruvbox-gtk-theme}:
# Gruvbox-GTK-Theme ships Gruvbox *Material* accents (sainnhe's newer, softer
# fork): teal #89b482, red #c14a4a, green #6c782e. Every other surface on this
# machine (hyprland, kitty, wayle, btop, tmux, nvim, Kvantum) uses the original
# morhetz palette, where the accent is aqua #8ec07c and red is #fb4934.
#
# The theme is compiled from sass at install time and its accent shades are all
# derived from the palette file with mix()/darken(), so recoloring the palette
# source is enough: every hover/active/disabled variant follows automatically.
# Patching the generated CSS instead would catch the base colors and miss the
# ~20 derived shades.
#
# Both the accents and the backgrounds are remapped, so every surface the dark
# theme paints is an official morhetz value. The only colors left untouched are:
#
#   - greys 900/950 (#0f0e0e, #0d0907): shadows and scrims. gruvbox defines no
#     shadow color, and a shadow is meant to be near-black rather than a palette
#     entry, so recoloring these would invent a color rather than restore one.
#   - greys 250/450 (#ccbeb8, #868686): light-theme only, never painted here
#     (verified: zero occurrences in the built dark CSS). Mapping them would
#     collide with neighbouring greys for no visible gain.
#   - the GNOME app palette (#1c71d8, #e01b24, ...) baked into the libadwaita
#     app stylesheets: those are specific apps' own brand colors, not the theme.
let
  # Material -> morhetz medium. The "-light" colors are the ones the light theme
  # uses (morhetz's neutral set) and "-dark" are for the dark theme (the bright
  # set). No target value appears as a source, so the order here cannot cascade.
  palette = {
    # red
    "#c14a4a" = "#cc241d";
    "#ea6962" = "#fb4934";
    # purple (morhetz has no distinct pink and purple; both map to its purple.
    # The theme's "pink" is already morhetz purple, so it is left untouched.)
    "#ab62b1" = "#b16286";
    "#d386cd" = "#d3869b";
    # blue
    "#45707a" = "#458588";
    "#7daea3" = "#83a598";
    # teal -> aqua. #8ec07c is the accent used across the rest of the system.
    "#4c7a5d" = "#689d6a";
    "#89b482" = "#8ec07c";
    # green
    "#6c782e" = "#98971a";
    "#a9b665" = "#b8bb26";
    # yellow
    "#b47109" = "#d79921";
    "#d8a657" = "#fabd2f";
    # orange
    "#c35e0a" = "#d65d0e";
    "#e78a4e" = "#fe8019";

    # Backgrounds. Greys 050-650 are already morhetz verbatim (#fbf1c7, #ebdbb2,
    # #d5c4a1, #bdae93, #a89984, #928374, #7c6f64, #665c54, #504945, #3c3836)
    # and $black is already #282828, so only the dark end below bg0 is Material.
    #
    # grey-700 is $base (text entries, lists, cards) and was #282524, a warm
    # near-black that is not a gruvbox color at all. Official Gruvbox Dark uses
    # bg0 #282828 for the normal background, so base becomes bg0 and matches the
    # window, which is the flat look the palette actually specifies.
    #
    # grey-750 is $surface and grey-850 is $menu: both sit *below* the window in
    # the theme's depth model. morhetz defines exactly one background darker
    # than bg0, the hard variant #1d2021, so all three recessed levels collapse
    # onto it. That keeps every painted surface a real gruvbox color at the cost
    # of one step of depth between surface and menu.
    "#282524" = "#282828"; # grey-700 -> bg0
    "#242220" = "#1d2021"; # grey-750 -> bg0_hard
    "#211f1e" = "#1d2021"; # grey-800 -> bg0_hard (blackness tweak only)
    "#141617" = "#1d2021"; # grey-850 -> bg0_hard
  };

  # GTK 2 needs its own map, because its template is not painted the way it
  # looks. gtkrc.sh treats certain hex values in themes/src/main/gtk-2.0 as
  # placeholder *tokens* and substitutes the real color at build time
  # (s/#1d2021/$background_dark/, s/#7daea3/$theme_color/, ...). Those
  # substitutions are lowercase while the template is uppercase (#1D2021,
  # #7DAEA3), so upstream's patterns never match and every one is a silent
  # no-op: the installed gtkrc is the template verbatim. Two consequences:
  #
  #   - The Teal build's selection stays Material *blue* #7DAEA3, because the
  #     token that was meant to become the accent is never substituted. So the
  #     accent has to be written into the template directly.
  #   - Reusing the map above here is actively harmful. It rewrites the tokens
  #     inside gtkrc.sh's own sed patterns, which turns those dormant no-ops
  #     into live substitutions. That is not hypothetical: mapping #282524 to
  #     #282828 rewrote `s/#282524/$titlebar_dark/` into `s/#282828/...`, and
  #     because #282828 is digits-only (case cannot save it) it then ate the
  #     window background and replaced it with #1d2021.
  #
  # So: write final colors into the template, and never touch a token.
  gtk2Palette = {
    "#F9F5D7" = "#fbf1c7"; # fg -> light0, matching theme_fg_color in GTK 3/4
    "#1D2021" = "#282828"; # bg and base -> bg0 (this is the medium variant)
    "#7DAEA3" = "#8ec07c"; # selection -> aqua, the accent upstream fails to set
    "#80AA9E" = "#689d6a"; # selection variant -> neutral aqua
    "#D386CD" = "#d3869b"; # purple
    # #282828 (titlebar), #504945 (tooltip) and #3C3836 are already morhetz.
  };

  mkSed = args: builtins.concatStringsSep " " (builtins.attrValues args);

  sedArgs = mkSed (builtins.mapAttrs (from: to: "-e 's/${from}/${to}/gI'") palette);

  gtk2SedArgs = mkSed (builtins.mapAttrs (from: to: "-e 's/${from}/${to}/gI'") gtk2Palette);

  # For gtkrc.sh itself: recolor only its value assignments and skip any line
  # that is a sed command, so the placeholder tokens in its patterns survive.
  # The values are unused today (the patterns no-op), but this keeps the file
  # self-consistent if upstream ever fixes the casing.
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

    # sass derives the shades, so the build can only be trusted if the compiled
    # CSS actually changed. A green build otherwise proves nothing.
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
