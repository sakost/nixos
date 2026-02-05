# Hardware configuration for sakost-pc (main PC)
# TODO: Run nixos-generate-config and update this file
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Kernel modules - update based on actual hardware
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];  # Change to kvm-amd if AMD CPU
  boot.extraModulePackages = [ ];

  # Use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Nvidia kernel parameter
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  # Boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Swap configuration
  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
  swapDevices = [ ];

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Firmware
  hardware.enableRedistributableFirmware = true;
}
