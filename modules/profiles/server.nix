# Headless server profile: runs this host as an unattended SSH-only server.
# Only enabled by the `sakost-server` flake output — never in the host config.
{ config, lib, ... }:

let
  cfg = config.custom.profiles.server;
in {
  options.custom.profiles.server = {
    enable = lib.mkEnableOption "headless server mode";
  };

  config = lib.mkIf cfg.enable {
    # Force the desktop off regardless of what the host config enables.
    custom.desktop.hyprland.enable = lib.mkForce false;
    custom.desktop.greetd.enable = lib.mkForce false;

    # An unattended box must never sleep.
    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
  };
}
