# Greetd display manager configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop.greetd;
in {
  options.custom.desktop.greetd = {
    enable = lib.mkEnableOption "Greetd display manager";
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd start-hyprland";
          user = "sakost";
        };
      };
    };
  };
}
