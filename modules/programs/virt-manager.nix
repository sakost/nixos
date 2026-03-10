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

    # Fix nixpkgs libvirt postPatch: it tries to substitute /usr/bin/sh in
    # virt-secret-init-encryption.service.in, but upstream libvirt 12.1.0 no longer
    # has that pattern. Remove the failing substituteInPlace from postPatch.
    nixpkgs.overlays = [
      (final: prev: {
        libvirt = prev.libvirt.overrideAttrs (old: {
          postPatch = builtins.replaceStrings
            [ "--replace-fail /usr/bin/sh" ]
            [ "--replace-warn /usr/bin/sh" ]
            (old.postPatch or "");
        });
      })
    ];

    # SPICE USB redirection — lets you pass USB devices into the VM
    virtualisation.spiceUSBRedirection.enable = true;

    # Add user to libvirt group for unprivileged VM management
    users.users.sakost.extraGroups = [ "libvirtd" ];
  };
}
