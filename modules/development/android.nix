{
  pkgs,
  inputs,
  ...
}: let
  # Reference android-nixpkgs sdk function for the current system
  android-nixpkgs = inputs.android-nixpkgs.sdk.${pkgs.system};

  # Define the Android SDK composition
  androidSdk = android-nixpkgs (
    sdkPkgs:
      with sdkPkgs; [
        # Core SDK components
        cmdline-tools-latest
        build-tools-35-0-0
        platforms-android-35
        tools
        platform-tools

        # Optional: Add more platforms or tools as needed
        platforms-android-34
        platforms-android-31

        build-tools-34-0-0
        build-tools-33-0-1
        build-tools-31-0-0

        # System images for emulator (optional)
        # system-images-android-35-google-apis-arm64-v8a
      ]
  );
  # Define the Android SDK composition
  # androidSdk = inputs.android-nixpkgs.sdk.${pkgs.system} (sdkPkgs:
  #   with sdkPkgs;
  #     [
  #       # Core SDK components
  #       cmdline-tools-latest
  #       build-tools-35-0-0
  #       platforms-android-35
  #       emulator
  #
  #       # Optional: Add more platforms or tools as needed
  #       build-tools-34-0-0
  #       platforms-android-34
  #       build-tools-31-0-0
  #       platforms-android-31
  #
  #       # System images for emulator (optional)
  #       # system-images-android-35-google-apis-arm64-v8a
  #     ]
  #     // {
  #       # Accept all necessary licenses
  #       licenseAccepted = true;
  #     });

  # Define ANDROID_HOME based on the SDK location
  ANDROID_HOME = "${androidSdk}/share/android-sdk";
in {
  # System packages for Android and Flutter development
  environment.systemPackages = with pkgs; [
    flutter # Flutter SDK
    androidSdk # The Android SDK from android-nixpkgs
    jdk17 # Java 17 for Android development
  ];

  # Enable ADB (Android Debug Bridge)
  programs.adb.enable = true;

  # Enable nix-ld for dynamic linking (useful for Flutter/Android tools)
  programs.nix-ld.enable = true;

  # Set environment variables
  environment.variables = {
    ANDROID_HOME = ANDROID_HOME;
    ANDROID_SDK_ROOT = ANDROID_HOME;
    # JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/35.0.0/aapt2";
  };
}
