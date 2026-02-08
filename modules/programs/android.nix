# Android device debugging support
{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.android-tools ];
}
