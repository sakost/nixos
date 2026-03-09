# Figma desktop app (unofficial Electron-based client for Linux)
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    figma-linux
    figma-agent
  ];
}
