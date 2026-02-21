# XDG Desktop Portals configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop.hyprland;
in {
  # This module activates when Hyprland is enabled
  config = lib.mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      configPackages = [
        pkgs.hyprland
      ];
    };
  };
}
