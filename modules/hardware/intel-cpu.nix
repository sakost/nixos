# Intel CPU configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.intel-cpu;

  capCpus = pkgs.writeShellScript "intel-cpu-freq-cap" ''
    for cpu in ${lib.concatMapStringsSep " " toString cfg.freqCap.cpus}; do
      echo ${toString cfg.freqCap.maxKHz} > /sys/devices/system/cpu/cpu$cpu/cpufreq/scaling_max_freq
    done
  '';
in {
  options.custom.hardware.intel-cpu = {
    enable = lib.mkEnableOption "Intel CPU optimizations";

    freqCap = {
      cpus = lib.mkOption {
        type = lib.types.listOf lib.types.ints.unsigned;
        default = [ ];
        example = [ 8 9 10 11 ];
        description = ''
          Logical CPUs whose scaling_max_freq is capped. For cores that
          degraded (Raptor Lake Vmin shift) at their top boost bin.
        '';
      };
      maxKHz = lib.mkOption {
        type = lib.types.ints.positive;
        default = 5700000;
        description = "Ceiling in kHz applied to freqCap.cpus.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Intel microcode updates
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

    # scaling_max_freq is not persistent: apply at boot and again after resume.
    systemd.services.intel-cpu-freq-cap = lib.mkIf (cfg.freqCap.cpus != [ ]) {
      description = "Cap max frequency of unstable CPU cores";
      wantedBy = [ "multi-user.target" "post-resume.target" ];
      after = [ "post-resume.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = capCpus;
      };
    };
  };
}
