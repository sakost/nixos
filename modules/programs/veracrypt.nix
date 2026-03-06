{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.veracrypt;
in {
  options.custom.programs.veracrypt = {
    enable = lib.mkEnableOption "VeraCrypt disk encryption";

    user = lib.mkOption {
      type = lib.types.str;
      default = "sakost";
      description = "User to grant passwordless sudo for veracrypt";
    };

    sudoNoPassword = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow veracrypt to be run with sudo without password (useful for scripts)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      veracrypt
      lvm2
      btrfs-progs
    ];

    boot.kernelModules = [ "loop" ];

    security.sudo.extraRules = lib.optional cfg.sudoNoPassword {
      users = [ cfg.user ];
      commands = [
        { command = "${pkgs.veracrypt}/bin/veracrypt";
          options = [ "NOPASSWD" ];
        }
      ];
    };
  };
}
