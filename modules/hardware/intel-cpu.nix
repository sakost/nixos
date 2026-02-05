# Intel CPU configuration module
{ config, lib, ... }:

let
  cfg = config.custom.hardware.intel-cpu;
in {
  options.custom.hardware.intel-cpu = {
    enable = lib.mkEnableOption "Intel CPU optimizations";
  };

  config = lib.mkIf cfg.enable {
    # Intel microcode updates
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
