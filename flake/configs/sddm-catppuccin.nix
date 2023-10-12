{
  stdenv,
  fetchFromGitHub,
}: {
  catppuccin-flavour = stdenv.mkDerivation {
    name = "catppuccin-flavour";
    pname = "catppuccin-flavour";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -aR $src/src/* $out/share/sddm/themes/
    '';
    src = fetchFromGitHub {
      owner = "catppuccin";
      repo = "sddm";
      rev = "7fc67d1027cdb7f4d833c5d23a8c34a0029b0661";
      sha256 = "sha256-SjYwyUvvx/ageqVH5MmYmHNRKNvvnF3DYMJ/f2/L+Go=";
    };
  };
}
