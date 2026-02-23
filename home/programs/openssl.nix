# OpenSSL configuration
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.openssl ];
}
