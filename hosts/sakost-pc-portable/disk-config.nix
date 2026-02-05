# Disk configuration for sakost-pc-portable
# LUKS encryption + BTRFS subvolumes
{ config, lib, ... }:

{
  # LUKS encryption
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/1edaf887-30d9-4808-b570-29a101292509";
    preLVM = true;
  };

  # BTRFS filesystem with subvolumes
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  # EFI boot partition
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C224-E385";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
