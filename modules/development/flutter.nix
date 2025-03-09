{pkgs, ...}: let
  buildToolsVersion = "34.0.0";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [buildToolsVersion "33.0.1"];
    platformVersions = ["35"];
    abiVersions = ["arm64-v8a"];
  };
  androidSdk = androidComposition.androidsdk;
in {
  nixpkgs = {
    config = {
      android_sdk = {
        accept_license = true;
      };
    };
  };
  environment = {
    systemPackages = with pkgs; [
      # flutter
      flutter
      androidSdk
      jdk17
    ];
    variables = {
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    };
  };
}
