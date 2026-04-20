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
        # virtiofsd — host-guest shared folders via virtiofs
        vhostUserPackages = [ pkgs.virtiofsd ];
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

    # swtpm_localca needs this directory writable by tss user for vTPM cert storage
    systemd.tmpfiles.rules = [
      "d /var/lib/swtpm-localca 0750 tss tss -"
    ];

    # NixOS libvirt doesn't ship a pre-defined "default" NAT network, so virt-manager
    # fails to start any VM that references it. This oneshot defines + autostarts it
    # idempotently on every activation.
    systemd.services.libvirt-default-network = let
      defaultNetworkXml = pkgs.writeText "libvirt-default-network.xml" ''
        <network>
          <name>default</name>
          <forward mode='nat'/>
          <bridge name='virbr0' stp='on' delay='0'/>
          <ip address='192.168.122.1' netmask='255.255.255.0'>
            <dhcp>
              <range start='192.168.122.2' end='192.168.122.254'/>
            </dhcp>
          </ip>
        </network>
      '';
    in {
      description = "Ensure libvirt default NAT network is defined and running";
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];
      wantedBy = [ "multi-user.target" ];
      environment.LIBVIRT_DEFAULT_URI = "qemu:///system";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu
        virsh=${pkgs.libvirt}/bin/virsh
        if ! "$virsh" net-info default >/dev/null 2>&1; then
          "$virsh" net-define ${defaultNetworkXml}
        fi
        "$virsh" net-autostart default
        if ! "$virsh" net-info default | grep -q '^Active:[[:space:]]*yes'; then
          "$virsh" net-start default
        fi
      '';
    };

    # SPICE USB redirection — lets you pass USB devices into the VM
    virtualisation.spiceUSBRedirection.enable = true;

    # Add user to libvirt group for unprivileged VM management
    users.users.sakost.extraGroups = [ "libvirtd" ];
  };
}
