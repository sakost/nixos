# Flutter + Android SDK development environment
{ config, pkgs, inputs, ... }:

let
  cacheBase = "${config.home.homeDirectory}/dev/cache";
in
{
  imports = [
    inputs.android-nixpkgs.hmModule
  ];

  android-sdk = {
    enable = true;
    path = "${config.xdg.dataHome}/android";

    packages = sdkPkgs: with sdkPkgs; [
      build-tools-34-0-0
      build-tools-35-0-0
      build-tools-36-1-0
      cmdline-tools-latest
      platform-tools
      platforms-android-34
      platforms-android-35
      platforms-android-36
      emulator
    ];
  };

  home.packages = with pkgs; [
    flutter
    jdk17
    mesa-demos
  ];

  home.sessionVariables = {
    JAVA_HOME = "${pkgs.jdk17.home}";
    GRADLE_USER_HOME = "${cacheBase}/gradle";
    CHROME_EXECUTABLE = "${pkgs.google-chrome}/bin/google-chrome-stable";
  };
}
