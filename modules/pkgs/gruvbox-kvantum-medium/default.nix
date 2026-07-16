{
  lib,
  runCommand,
  python3,
  gruvbox-kvantum,
}:
# gruvbox-kvantum ships exactly one theme, "Gruvbox-Dark-Brown" (a partial
# re-color of KvAdapta with brown highlights). It has no medium-contrast variant
# and no aqua accent, so this derives one. See recolor.py for the mapping and why
# each color was chosen.
runCommand "gruvbox-kvantum-medium-${gruvbox-kvantum.version}" {
  nativeBuildInputs = [python3];

  meta = with lib; {
    description = "Gruvbox Dark medium-contrast Kvantum theme with aqua accents";
    longDescription = ''
      Derived from gruvbox-kvantum's Gruvbox-Dark-Brown: window chrome moved to
      gruvbox bg0 (#282828), accent surfaces moved to aqua (#8ec07c) to match
      hyprland, kitty and wayle, and the text drawn on those surfaces darkened to
      stay readable.
    '';
    inherit (gruvbox-kvantum.meta) license;
    platforms = platforms.all;
  };
} ''
  python3 ${./recolor.py} \
    ${gruvbox-kvantum}/share/Kvantum/Gruvbox-Dark-Brown \
    $out/share/Kvantum/Gruvbox-Dark-Medium
''
