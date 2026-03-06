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

    # Fix hardcoded /usr/bin/sh in libvirt's virt-secret-init-encryption.service
    # The upstream libvirt package ships this unit with /usr/bin/sh which doesn't exist on NixOS
    nixpkgs.overlays = [
      (final: prev: {
        libvirt = prev.libvirt.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            if [ -f $out/lib/systemd/system/virt-secret-init-encryption.service ]; then
              substituteInPlace $out/lib/systemd/system/virt-secret-init-encryption.service \
                --replace-fail '/usr/bin/sh' '${prev.bash}/bin/bash'
            fi
          '';
        });
      })
    ];

    # SPICE USB redirection — lets you pass USB devices into the VM
    virtualisation.spiceUSBRedirection.enable = true;

    # Add user to libvirt group for unprivileged VM management
    users.users.sakost.extraGroups = [ "libvirtd" ];
  };
}
