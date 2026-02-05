# GUI applications
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    telegram-desktop
    google-chrome
  ];
}
