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
    networking.networkmanager.dns = "none";
    networking.search = lib.mkForce [];
    networking.resolvconf.extraOptions = [ "ndots:0" "timeout:1" ];
  };
}
