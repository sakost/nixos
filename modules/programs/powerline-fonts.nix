# Powerline-patched fonts for terminal prompts and status lines
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.powerline-fonts;
in {
  options.custom.programs.powerline-fonts = {
    enable = lib.mkEnableOption "Powerline-patched fonts";
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      powerline-fonts
      powerline-symbols
    ];
  };
}
