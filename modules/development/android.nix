{
  pkgs,
  inputs,
  ...
}: let
  android-nixpkgs = inputs.android-nixpkgs.sdk.${pkgs.system};

  androidSdk = android-nixpkgs (
    sdk:
      with sdk; [
        platform-tools
        cmdline-tools-latest
        platforms-android-35
        platforms-android-34
        platforms-android-31
        build-tools-35-0-0
        build-tools-34-0-0
        build-tools-33-0-1
        build-tools-31-0-0
      ]
  );
  ANDROID_HOME = "${androidSdk}/share/android-sdk";
in {
  environment = {
    systemPackages = with pkgs; [
      flutter
      androidSdk
      jdk17
    ];
    variables = {
      ANDROID_HOME = ANDROID_HOME;
      ANDROID_SDK_ROOT = ANDROID_HOME;
      GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/35.0.0/aapt2";
    };
  };

  services = {
    udev = {
      packages = [pkgs.android-udev-rules];
    };
  };

  users = {
    groups = {
      adbusers = {};
    };
  };
}
