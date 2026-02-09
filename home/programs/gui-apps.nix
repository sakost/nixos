# GUI applications
{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    telegram-desktop
    google-chrome
    inputs.yandex-browser.packages.x86_64-linux.default
    zoom-us
  ];
}
