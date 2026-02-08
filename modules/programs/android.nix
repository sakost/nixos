# Android device debugging support (ADB udev rules)
{ pkgs, ... }:

{
  services.udev.packages = [ pkgs.android-udev-rules ];
  environment.systemPackages = [ pkgs.android-tools ];
}
