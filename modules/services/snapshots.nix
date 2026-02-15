{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.snapshots;
in
{
  options.custom.services.snapshots = {
    enable = lib.mkEnableOption "BTRFS snapshot management via btrbk";
  };

  config = lib.mkIf cfg.enable {
    services.btrbk.instances = {
      hourly = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "48h";
          snapshot_preserve = "14d";
          volume."/mnt/btrfs-roots/data" = {
            snapshot_dir = "@data-snapshots";
            subvolume."@dev" = {};
          };
        };
      };

      daily = {
        onCalendar = "daily";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "14d";
          snapshot_preserve = "8w";
          volume."/mnt/btrfs-roots/system" = {
            snapshot_dir = "@snapshots";
            subvolume."@" = {};
            subvolume."@home" = {};
          };
        };
      };

      weekly = {
        onCalendar = "weekly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "4w";
          snapshot_preserve = "6m";
          volume."/mnt/btrfs-roots/data" = {
            snapshot_dir = "@data-snapshots";
            subvolume."@data" = {};
            subvolume."@models" = {};
          };
        };
      };
    };
  };
}
