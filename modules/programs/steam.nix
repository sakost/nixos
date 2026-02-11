# Steam gaming platform (system-level)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.steam;
in {
  options.custom.programs.steam = {
    enable = lib.mkEnableOption "Steam gaming platform";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    # Steam controller and other Steam hardware support
    hardware.steam-hardware.enable = true;

    # Gamemode — on-demand performance optimisation daemon
    programs.gamemode.enable = true;
  };
}
