{pkgs, ...}: let
  buildToolsVersion = "35.0.0";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [buildToolsVersion "34.0.0" "31.0.0"];
    platformVersions = ["35" "34" "31"];
    abiVersions = ["armeabi-v7a" "arm64-v8a"];
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
  ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
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
      ANDROID_HOME = ANDROID_HOME;
      ANDROID_SDK_ROOT = ANDROID_HOME;
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolsVersion}/aapt2";
    };
  };
}
