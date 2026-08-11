{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  sassc,
  gnome-themes-extra,
  colorVariants ? [],
  sizeVariants ? [],
  themeVariants ? [],
  tweakVariants ? [],
  iconVariants ? [],
}:
# Vendored from nixpkgs, which removed gruvbox-gtk-theme in commit 20282c92
# because it propagated gtk-engine-murrine (a GTK 2 render engine, removed as
# unmaintained). Murrine only affects how GTK 2 apps *draw* the theme; nothing
# here needs it at build time, so it is simply dropped. GTK 2 apps fall back
# to the default engine, everything GTK 3/4 is unaffected.
let
  pname = "gruvbox-gtk-theme";
  colorVariantList = [
    "dark"
    "light"
  ];
  sizeVariantList = [
    "compact"
    "standard"
  ];
  themeVariantList = [
    "default"
    "green"
    "grey"
    "orange"
    "pink"
    "purple"
    "red"
    "teal"
    "yellow"
    "all"
  ];
  tweakVariantList = [
    "medium"
    "soft"
    "black"
    "float"
    "outline"
    "macos"
  ];
  iconVariantList = [
    "Dark"
    "Light"
  ];
in
  lib.checkListOfEnum "${pname}: colorVariants" colorVariantList colorVariants lib.checkListOfEnum
  "${pname}: sizeVariants"
  sizeVariantList
  sizeVariants
  lib.checkListOfEnum
  "${pname}: themeVariants"
  themeVariantList
  themeVariants
  lib.checkListOfEnum
  "${pname}: tweakVariants"
  tweakVariantList
  tweakVariants
  lib.checkListOfEnum
  "${pname}: iconVariants"
  iconVariantList
  iconVariants
  stdenvNoCC.mkDerivation
  {
    inherit pname;
    version = "0-unstable-2025-10-23";

    src = fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Gruvbox-GTK-Theme";
      rev = "578cd220b5ff6e86b078a6111d26bb20ec8c733f";
      hash = "sha256-RXoPj/aj9OCTIi8xWatG0QpDAUh102nFOipdSIiqt7o=";
    };

    nativeBuildInputs = [sassc];
    buildInputs = [gnome-themes-extra];

    dontBuild = true;

    postPatch = ''
      patchShebangs themes/install.sh
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/themes
      cd themes
      ./install.sh -n Gruvbox \
      ${lib.optionalString (colorVariants != []) "-c " + toString colorVariants} \
      ${lib.optionalString (sizeVariants != []) "-s " + toString sizeVariants} \
      ${lib.optionalString (themeVariants != []) "-t " + toString themeVariants} \
      ${lib.optionalString (tweakVariants != []) "--tweaks " + toString tweakVariants} \
      -d "$out/share/themes"
      cd ../icons
      ${lib.optionalString (iconVariants != []) ''
        mkdir -p $out/share/icons
        cp -a ${toString (map (v: "Gruvbox-${v}") iconVariants)} $out/share/icons/
      ''}
      runHook postInstall
    '';

    meta = {
      description = "GTK theme based on the Gruvbox colour palette";
      homepage = "https://github.com/Fausto-Korpsvart/Gruvbox-GTK-Theme";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.unix;
    };
  }
