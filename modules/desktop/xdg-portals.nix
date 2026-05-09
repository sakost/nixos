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

    # Bind the portal stack to pipewire so a pipewire restart (e.g. when a
    # rebuild touches services.pipewire.*) cleanly cycles the portals too.
    # Otherwise the portals keep stale handles to the old pipewire instance,
    # which deadlocks GTK4 clients (waybar, walker) at the
    # xdg-desktop-portal.GetSettings() call for ~50s on every restart and
    # prevents waybar from creating its layer-shell surface at all.
    # The portals are dbus-activated, so they respawn on the next caller.
    systemd.user.services =
      let
        bindToPipewire = {
          unitConfig = {
            PartOf = [ "pipewire.service" ];
            After = [ "pipewire.service" ];
          };
        };
      in {
        xdg-desktop-portal = bindToPipewire;
        xdg-desktop-portal-gtk = bindToPipewire;
        xdg-desktop-portal-hyprland = bindToPipewire;
      };
  };
}
