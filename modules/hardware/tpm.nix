# TPM2 configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.tpm;
in {
  options.custom.hardware.tpm = {
    enable = lib.mkEnableOption "TPM2 support";
  };

  config = lib.mkIf cfg.enable {
    security.tpm2.enable = true;
    security.tpm2.pkcs11.enable = true;
    security.tpm2.tctiEnvironment.enable = true;

    boot.initrd.availableKernelModules = [ "tpm_tis" "tpm_crb" ];
    boot.initrd.systemd.tpm2.enable = true;

    environment.systemPackages = [ pkgs.tpm2-tools ];
  };
}
