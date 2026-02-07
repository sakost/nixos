# Proxy service module (sing-box with VLESS Reality)
# Uses SOPS to store the entire sing-box config file encrypted
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.proxy;
in {
  options.custom.services.proxy = {
    enable = lib.mkEnableOption "sing-box proxy service";
  };

  config = lib.mkIf cfg.enable {
    # SOPS secret - entire sing-box config stored as binary
    sops.secrets."sing-box-config" = {
      sopsFile = ../../../secrets/sing-box.json;
      format = "binary";
      mode = "0400";
    };

    # sing-box package
    environment.systemPackages = [ pkgs.sing-box ];

    # Custom systemd service that reads config from SOPS secret path
    systemd.services.sing-box-proxy = {
      description = "sing-box Proxy Service";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c ${config.sops.secrets."sing-box-config".path}";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        DynamicUser = false;  # Need root for TUN
        AmbientCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
        CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_BIND_SERVICE" "CAP_NET_RAW" ];
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        StateDirectory = "sing-box";
        WorkingDirectory = "/var/lib/sing-box";
      };
    };

    # Required for TUN mode
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Firewall rules for sing-box TUN
    networking.firewall = {
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      # TUN interface traffic
      trustedInterfaces = [ "sing-tun" ];
    };
  };
}
