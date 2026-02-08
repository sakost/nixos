# Logitech mouse configuration module (G502 via piper/libratbag)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.mouse;
in {
  options.custom.hardware.mouse = {
    enable = lib.mkEnableOption "Logitech mouse support (piper/ratbagd)";
  };

  config = lib.mkIf cfg.enable {
    # Solaar for wireless Logitech devices (Lightspeed/Unifying receiver)
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    # ratbagd daemon for DPI, button mapping, RGB, profile management
    services.ratbagd.enable = true;

    # Piper GUI frontend for ratbagd
    environment.systemPackages = [ pkgs.piper ];
  };
}
