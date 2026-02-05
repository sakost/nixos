# OpenSSH configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.ssh;
in {
  options.custom.services.ssh = {
    enable = lib.mkEnableOption "OpenSSH server";
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
  };
}
