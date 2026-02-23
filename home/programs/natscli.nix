# NATS CLI client configuration
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.natscli ];
}
