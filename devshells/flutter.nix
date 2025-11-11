{
  pkgs,
  inputs,
  ...
}: let
  android-nixpkgs = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system};

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
in
  pkgs.mkShell {
    name = "Flutter";

    ANDROID_HOME = ANDROID_HOME;
    ANDROID_SDK_ROOT = ANDROID_HOME;
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/35.0.0/aapt2";
    buildInputs = with pkgs; [
      libsecret
      flutter
      androidSdk
      jdk17
    ];
  }
