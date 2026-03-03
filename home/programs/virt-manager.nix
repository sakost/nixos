# virt-manager — GUI frontend for QEMU/KVM virtual machines
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.virt-manager ];
}
