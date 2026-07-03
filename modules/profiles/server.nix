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

    # The home-manager hyprland module auto-enables its xdg.portal module,
    # whose assertion requires the (disabled) system portal stack. No
    # graphical session exists in server mode, so switch it off entirely.
    home-manager.users.sakost.wayland.windowManager.hyprland.enable = lib.mkForce false;

    # Brute-force protection for the internet-exposed SSH port.
    # LAN and Tailscale ranges are exempt so the backup path can never be banned.
    services.fail2ban = {
      enable = true;
      ignoreIP = [
        "192.168.1.0/24" # home LAN
        "100.64.0.0/10" # Tailscale CGNAT range
      ];
    };
    services.openssh.settings.MaxAuthTries = 3;

    # Tailscale: independent backup access path that needs no router port-forward.
    # One-time `sudo tailscale up` login required before leaving (docs/server-mode.md).
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
  };
}
