# GUI applications
{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    telegram-desktop
    google-chrome
    inputs.claude-desktop.packages.x86_64-linux.claude-desktop
    inputs.yandex-browser.packages.x86_64-linux.default
    spotify
    zoom-us
  ];
}
