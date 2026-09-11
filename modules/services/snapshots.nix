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
          # @dev churns hard (Rust workspaces, 50+ git worktrees). Keep a short
          # window only: 2h of everything, then 4 hourly + 1 daily.
          snapshot_preserve_min = "2h";
          snapshot_preserve = "4h 1d";
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
          snapshot_preserve_min = "3d";
          snapshot_preserve = "7d 4w";
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
          snapshot_preserve_min = "2w";
          snapshot_preserve = "4w 3m";
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
