{pkgs, ...}: let
  buildToolsVersion = "34.0.0";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [buildToolsVersion "33.0.1"];
    platformVersions = ["35"];
    abiVersions = ["arm64-v8a"];
    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "mips-android-sysimage-license"

      "android-sdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
    ];
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
  programs = {
    adb = {
      enable = true;
    };
    nix-ld = {
      enable = true;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      flutter
      androidSdk
      jdk17
    ];
    variables = {
      ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
    };
  };
}
