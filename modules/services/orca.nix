{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.orca;
  orcaPackage = pkgs.callPackage ../../packages/orca.nix { };
  userHome = config.users.users.${cfg.user}.home;

  # `orca serve` registers ~/.local/bin/orca-ide as a symlink to its launcher
  # and refuses to replace a symlink whose target it does not recognise; a
  # /nix/store path never is. Store paths change on every update, so drop a
  # link left behind by a previous Orca install and let the current one
  # register itself. Foreign files and symlinks are left alone.
  pruneStaleCli = pkgs.writeShellScript "orca-serve-prune-stale-cli" ''
    set -eu
    link=${userHome}/.local/bin/orca-ide
    [ -L "$link" ] || exit 0
    current=$(readlink -f ${cfg.package}/bin/orca-ide)
    target=$(readlink -f "$link" 2>/dev/null || readlink "$link")
    case "$target" in
      "$current") ;;
      /nix/store/*-orca-*-extracted/resources/bin/orca-ide)
        echo "removing stale Orca CLI link $link -> $target"
        rm -f "$link"
        ;;
    esac
  '';

  # Orca runs inside a bubblewrap FHS env, and bwrap sets no_new_privs on
  # everything it spawns -- Orca's terminals and agents included. Under
  # no_new_privs, newuidmap/newgidmap cannot gain CAP_SETUID/CAP_SETGID
  # (setuid bits and file capabilities are both ignored), so a rootless
  # `podman`/`docker` started from an Orca terminal builds a single-uid user
  # namespace and caches it in the shared pause process, which then breaks
  # podman for every other session ("insufficient UIDs or GIDs available").
  # CONTAINER_HOST switches the CLI into remote mode: the real work happens in
  # podman.service under the user's systemd instance, outside the sandbox.
  # The uid is resolved at runtime because the user has no static uid.
  serve = pkgs.writeShellScript "orca-serve" ''
    export CONTAINER_HOST="unix:///run/user/$(${pkgs.coreutils}/bin/id -u)/podman/podman.sock"
    exec ${lib.getExe cfg.package} serve --port ${toString cfg.port} --pairing-address ${cfg.pairingAddress} --json
  '';
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
        ExecStartPre = pruneStaleCli;
        ExecStart = serve;
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
