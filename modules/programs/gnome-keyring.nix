# GNOME Keyring — secret-service provider, SSH agent, and credential storage
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.gnome-keyring;
in {
  options.custom.programs.gnome-keyring = {
    enable = lib.mkEnableOption "GNOME Keyring secret service";
  };

  config = lib.mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
