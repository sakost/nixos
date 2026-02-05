# AMD CPU configuration module
{ config, lib, ... }:

let
  cfg = config.custom.hardware.amd-cpu;
in {
  options.custom.hardware.amd-cpu = {
    enable = lib.mkEnableOption "AMD CPU optimizations";
  };

  config = lib.mkIf cfg.enable {
    # AMD microcode updates
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
