{ config, lib, ... }:

{
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/442f8c91-0b7a-45bb-b479-3dfda29fc07e";
  };

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@home"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@nix"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@var-log"
      "compress=zstd:3"
      "noatime"
    ];
    neededForBoot = true;
  };

  fileSystems."/.snapshots" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@snapshots"
      "compress=zstd:1"
      "noatime"
    ];
  };

  fileSystems."/swap" = {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=@swap"
      "noatime"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/A2CB-38C0";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  fileSystems."/home/sakost/games" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@games"
      "noatime"
      "nodatacow"
    ];
  };
  fileSystems."/home/sakost/dev" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@dev"
      "compress=zstd:1"
      "noatime"
    ];
  };
  fileSystems."/home/sakost/dev/models" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@models"
      "compress=zstd:3"
      "noatime"
    ];
  };
  fileSystems."/home/sakost/dev/data" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@data"
      "compress=zstd:1"
      "noatime"
    ];
  };
  fileSystems."/home/sakost/dev/cache" = {
    device = "/dev/mapper/cryptdata";
    fsType = "btrfs";
    options = [
      "subvol=@cache"
      "nodatacow"
      "noatime"
    ];
  };

}
