# Hardware configuration for sakost-pc
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernelParams = [ "nvidia-drm.modeset=1" "resume_offset=533760" ];
  boot.resumeDevice = "/dev/mapper/cryptroot";

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.initrd.systemd.enable = true;

  zramSwap = {
    enable = true;
    memoryPercent = 25;
  };
  swapDevices = [{
    device = "/swap/swapfile";
  }];

  # Platform
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Firmwares
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
