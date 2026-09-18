# Network configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.networking;
in {
  options.custom.services.networking = {
    enable = lib.mkEnableOption "NetworkManager";
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;

    # systemd-resolved owns /etc/resolv.conf (symlink to its stub resolver).
    # NetworkManager pushes DHCP nameservers into it per link, and Tailscale
    # pushes MagicDNS the same way — nothing rewrites the file by hand.
    # (Enabling resolved also sets networkmanager.dns = "systemd-resolved".)
    services.resolved.enable = true;
  };
}
