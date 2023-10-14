{
  pkgs,
  stdenv,
  fetchFromGitHub,
}: let
  imgLink = "https://github.com/francoisrob/dotfiles/blob/main/resources/mocha_mountain.jpg";
  image = pkgs.fetchurl {
    url = imgLink;
    hash = "sha256-69Z+Z9M8uHnCtpOmhqGvh+HE7IRg4tm3+TvnP6EeylM=";
  };
in {
  catppuccin-flavour = stdenv.mkDerivation {
    name = "catppuccin-flavour";
    pname = "catppuccin-flavour";
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -aR $src/src/* $out/share/sddm/themes/
      chmod -R a=r,u+w,a+X $out/share/sddm/themes/catppuccin-mocha/backgrounds
      cp -r ${image} $out/share/sddm/themes/catppuccin-mocha/backgrounds/wall.jpg
    '';
    src = fetchFromGitHub {
      owner = "catppuccin";
      repo = "sddm";
      rev = "7fc67d1027cdb7f4d833c5d23a8c34a0029b0661";
      sha256 = "sha256-SjYwyUvvx/ageqVH5MmYmHNRKNvvnF3DYMJ/f2/L+Go=";
    };
  };
}
