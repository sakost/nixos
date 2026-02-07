# Rofi application launcher configuration
{ config, pkgs, ... }:

{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = "gruvbox-dark-hard";

    extraConfig = {
      show-icons = true;
      icon-theme = "Papirus-Dark";
      display-drun = "Apps";
      drun-display-format = "{name}";
    };
  };
}
