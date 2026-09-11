{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.orca;
  orcaPackage = pkgs.callPackage ../../packages/orca.nix { };
  userHome = config.users.users.${cfg.user}.home;
in
{
  options.custom.services.orca = {
    enable = lib.mkEnableOption "headless Orca runtime server";

    package = lib.mkOption {
      type = lib.types.package;
      default = orcaPackage;
      description = "Orca package to run.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "sakost";
      description = "Unprivileged user whose projects and agent credentials Orca uses.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 6768;
      description = "Local WebSocket port exposed through the SSH tunnel.";
    };

    pairingAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address advertised to the Orca client; loopback is correct for SSH forwarding.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.hasAttr cfg.user config.users.users;
        message = "custom.services.orca.user must name an existing NixOS user";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    systemd.services.orca-serve = {
      description = "Orca runtime server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      # Orca starts its own Xvfb when DISPLAY is unset, but Xvfb must be on PATH.
      path = [ pkgs.xorg-server ];
      environment.LIBGL_ALWAYS_SOFTWARE = "1";

      unitConfig = {
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        WorkingDirectory = userHome;
        ExecStart = "${lib.getExe cfg.package} serve --port ${toString cfg.port} --pairing-address ${cfg.pairingAddress} --json";
        StandardOutput = "journal";
        StandardError = "journal";
        KillMode = "mixed";
        Restart = "on-failure";
        RestartPreventExitStatus = 3;
        RestartSec = 5;
      };
    };
  };
}
