# QEMU/KVM virtualisation with virt-manager (system-level)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.virt-manager;
in {
  options.custom.programs.virt-manager = {
    enable = lib.mkEnableOption "QEMU/KVM virtualisation with virt-manager";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        # swtpm — software TPM emulator, required for Windows 11
        swtpm.enable = true;
      };
    };

    # SPICE USB redirection — lets you pass USB devices into the VM
    virtualisation.spiceUSBRedirection.enable = true;

    # Add user to libvirt group for unprivileged VM management
    users.users.sakost.extraGroups = [ "libvirtd" ];
  };
}
