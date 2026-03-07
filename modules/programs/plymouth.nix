# Plymouth boot splash with catppuccin theme
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.plymouth;
in
{
  options.custom.programs.plymouth = {
    enable = lib.mkEnableOption "Plymouth boot splash";
  };

  config = lib.mkIf cfg.enable {
    boot.plymouth = {
      enable = true;
      theme = "catppuccin-mocha";
      themePackages = [
        (pkgs.catppuccin-plymouth.override { variant = "mocha"; })
      ];
    };

    # Silent boot: reduce kernel verbosity for clean splash
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
  };
}
