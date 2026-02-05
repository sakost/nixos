# Bluetooth configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.bluetooth;
in {
  options.custom.hardware.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth support";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;

    # Bluetooth manager GUI (also adds package automatically)
    services.blueman.enable = true;
  };
}
