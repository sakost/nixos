# Hardware configuration for sakost-pc
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  # Force-load the AES-NI/VAES driver before systemd-cryptsetup opens the LUKS
  # devices. The crypto API binds an implementation at device-open time; without
  # this, the mappings fall back to the generic xts(ecb(aes-lib)) software path
  # (priority 100, vs 600 for xts-aes-vaes-avx2) for the life of the boot -- both
  # much slower and the path the 7.1.8 dm-crypt panic lives in.
  boot.initrd.kernelModules = [ "aesni_intel" ];
  boot.kernelModules = [ "kvm-intel" "i2c-dev" ];
  boot.extraModulePackages = [ ];

  # Pinned off linuxPackages_latest. 7.1.8 panics in the dm-crypt XTS-AES write
  # path (kcryptd_crypt -> crypt_convert -> xts_encrypt -> aes_encrypt_arch ->
  # kernel_fpu_begin_mask, NULL deref at 0x2e): three panics in ten days, all the
  # same stack, none in sixteen days on 7.1.4. See memory/fixes.md 2026-08-23.
  # Revisit once a 7.1.x past .8 is in nixpkgs.
  boot.kernelPackages = pkgs.linuxPackages;

  # panic=10: reboot ten seconds after a panic rather than sitting dead until the
  # hardware watchdog (or a human) intervenes -- this host is reached over SSH.
  boot.kernelParams = [ "nvidia-drm.modeset=1" "resume_offset=533760" "panic=10" ];
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
