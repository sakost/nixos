# Disk configuration for sakost-pc (2x NVMe setup)
# TODO: Configure this based on actual disk layout
# Options to consider:
#   - RAID0 for performance (risky, no redundancy)
#   - RAID1 for redundancy (mirrors data)
#   - Separate disks: one for system, one for data/games
#   - LUKS on each disk or single LUKS spanning both
{ config, lib, ... }:

{
  # Example LUKS encryption - update UUIDs after installation
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    preLVM = true;
  };

  # Example BTRFS layout - customize as needed
  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  # EFI boot partition - update UUID after installation
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-WITH-ACTUAL-UUID";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
