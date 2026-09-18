# Tailscale module: reach this box from anywhere by name, without knowing its
# IP or opening a router port. With MagicDNS the node is `sakost-pc` from any
# device on the tailnet.
# One-time `sudo tailscale up` login is required; the node key then persists
# in /var/lib/tailscale. Disable key expiry for this node in the admin console
# so it never silently drops off while unattended.
{ config, lib, ... }:

let
  cfg = config.custom.services.tailscale;
in {
  options.custom.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale client";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    # Trust the tunnel so sshd (and anything else) is reachable over it
    # without per-service firewall openings.
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];
  };
}
