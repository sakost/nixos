# Hardware temperature sensors (coretemp + lm_sensors)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.sensors;
in {
  options.custom.hardware.sensors = {
    enable = lib.mkEnableOption "CPU temperature sensors via coretemp and lm_sensors";
  };

  config = lib.mkIf cfg.enable {
    # Intel per-core digital thermal sensor driver
    boot.kernelModules = [ "coretemp" ];

    # `sensors` CLI for reading hwmon data; run `sensors-detect` to probe
    # for additional chips (e.g. motherboard Super I/O)
    environment.systemPackages = [ pkgs.lm_sensors ];
  };
}
