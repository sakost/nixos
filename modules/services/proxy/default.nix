# Proxy service module (sing-box with subscription fetcher + TUI selector)
# Static config in /etc/sing-box/config.json, dynamic outbounds in /var/lib/sing-box/outbounds.json
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.services.proxy;

  # Static sing-box configuration (no proxy outbounds — those come from outbounds.json)
  staticConfig = builtins.toJSON {
    log = {
      level = "warn";
      timestamp = true;
    };

    dns = {
      servers = [
        {
          type = "https";
          tag = "google";
          server = "8.8.8.8";
        }
        {
          type = "https";
          tag = "local";
          server = "77.88.8.8";
        }
      ];
      rules = [
        {
          rule_set = "geosite-category-ru";
          server = "local";
        }
      ];
      final = "google";
      strategy = "ipv4_only";
      independent_cache = true;
    };

    inbounds = [
      {
        type = "tun";
        tag = "tun-in";
        interface_name = "sing-tun";
        address = [ "172.19.0.1/30" ];
        mtu = 1492;
        auto_route = true;
        strict_route = true;
        stack = "mixed";
      }
      {
        type = "direct";
        tag = "dns-in";
        listen = "127.0.0.1";
        listen_port = 53;
        network = "udp";
      }
    ];

    outbounds = [
      { type = "direct"; tag = "direct"; }
      { type = "block"; tag = "block"; }
    ];

    route = {
      rules = [
        { action = "sniff"; }
        { action = "hijack-dns"; protocol = "dns"; }
        { ip_is_private = true; outbound = "direct"; }
        { domain_suffix = [ ".local" ".lan" ".localhost" ]; outbound = "direct"; }
        { rule_set = [ "geosite-category-ru" "geoip-ru" ]; outbound = "direct"; }
        { rule_set = "geosite-category-ads-all"; outbound = "block"; }
      ];
      rule_set = [
        {
          tag = "geosite-category-ru";
          type = "remote";
          format = "binary";
          url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ru.srs";
          download_detour = "direct";
        }
        {
          tag = "geoip-ru";
          type = "remote";
          format = "binary";
          url = "https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-ru.srs";
          download_detour = "direct";
        }
        {
          tag = "geosite-category-ads-all";
          type = "remote";
          format = "binary";
          url = "https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-category-ads-all.srs";
          download_detour = "direct";
        }
      ];
      final = "proxy";
      auto_detect_interface = true;
      default_domain_resolver = "local";
    };

    experimental = {
      cache_file = {
        enabled = true;
        path = "/var/lib/sing-box/cache.db";
      };
      clash_api = {
        external_controller = "127.0.0.1:${toString cfg.clashApiPort}";
        external_ui = "/var/lib/sing-box/ui";
        external_ui_download_url = "https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip";
        external_ui_download_detour = "direct";
      };
    };
  };

  staticConfigFile = pkgs.writeText "sing-box-config.json" staticConfig;

  # Python fetcher script for subscription updates
  fetcherScript = pkgs.writeScriptBin "sing-box-fetch-subscription" ''
    #!${pkgs.python3}/bin/python3
    """
    Fetch sing-box subscription outbounds and write /var/lib/sing-box/outbounds.json.
    Uses dig + curl --resolve to bypass local DNS (which points to sing-box).
    """
    import json
    import os
    import subprocess
    import sys
    import tempfile
    from urllib.parse import urlparse

    OUTBOUNDS_PATH = "/var/lib/sing-box/outbounds.json"
    STATIC_CONFIG = "/etc/sing-box/config.json"
    SUB_URL_PATH = "${config.sops.secrets."sing-box-sub-url".path}"
    SING_BOX = "${pkgs.sing-box}/bin/sing-box"
    CURL = "${pkgs.curl}/bin/curl"
    DIG = "${pkgs.dnsutils}/bin/dig"
    SYSTEMCTL = "${pkgs.systemd}/bin/systemctl"

    PROXY_TYPES = {
        "vless", "vmess", "trojan", "shadowsocks",
        "hysteria", "hysteria2", "tuic", "wireguard", "ssh",
    }

    def resolve_via_google(hostname):
        """Resolve hostname using dig @8.8.8.8 to bypass local DNS."""
        try:
            result = subprocess.run(
                [DIG, "+short", "@8.8.8.8", hostname],
                capture_output=True, text=True, timeout=5,
            )
            if result.returncode == 0:
                for line in result.stdout.strip().split("\n"):
                    line = line.strip()
                    if line and not line.endswith("."):  # skip CNAMEs
                        return line
        except Exception as e:
            print(f"Warning: DNS resolution via 8.8.8.8 failed for {hostname}: {e}", file=sys.stderr)
        return None

    def main():
        # Read subscription URL
        try:
            with open(SUB_URL_PATH) as f:
                sub_url = f.read().strip()
        except Exception as e:
            print(f"Error reading subscription URL: {e}", file=sys.stderr)
            sys.exit(1)

        if not sub_url:
            print("Error: subscription URL is empty", file=sys.stderr)
            sys.exit(1)

        # Resolve hostname via 8.8.8.8 to avoid chicken-and-egg with sing-box DNS
        parsed = urlparse(sub_url)
        hostname = parsed.hostname
        port = parsed.port or (443 if parsed.scheme == "https" else 80)

        curl_args = [CURL, "-s", "--max-time", "30", "-A", "SFA"]
        ip = resolve_via_google(hostname)
        if ip:
            curl_args += ["--resolve", f"{hostname}:{port}:{ip}"]
        curl_args.append(sub_url)

        # Fetch subscription
        try:
            result = subprocess.run(curl_args, capture_output=True, text=True, timeout=35)
            if result.returncode != 0:
                print(f"Error fetching subscription: curl exit {result.returncode}: {result.stderr}", file=sys.stderr)
                sys.exit(1)
            data = json.loads(result.stdout)
        except json.JSONDecodeError as e:
            print(f"Error: subscription returned invalid JSON: {e}", file=sys.stderr)
            sys.exit(1)
        except Exception as e:
            print(f"Error fetching subscription: {e}", file=sys.stderr)
            sys.exit(1)

        # Extract proxy outbounds
        raw_outbounds = data.get("outbounds", [])
        proxy_outbounds = [ob for ob in raw_outbounds if ob.get("type") in PROXY_TYPES]

        if not proxy_outbounds:
            print("Error: subscription returned zero proxy outbounds", file=sys.stderr)
            sys.exit(1)

        tags = [ob["tag"] for ob in proxy_outbounds]

        # Build outbounds.json with selector + urltest + proxy outbounds
        outbounds_config = {
            "outbounds": [
                {
                    "type": "selector",
                    "tag": "proxy",
                    "outbounds": ["auto"] + tags,
                    "interrupt_exist_connections": True,
                },
                {
                    "type": "urltest",
                    "tag": "auto",
                    "outbounds": tags,
                    "url": "http://www.gstatic.com/generate_204",
                    "interval": "5m",
                },
            ] + proxy_outbounds
        }

        candidate_json = json.dumps(outbounds_config, indent=2, ensure_ascii=False)

        # Compare with existing outbounds.json first (avoid unnecessary work)
        if os.path.exists(OUTBOUNDS_PATH):
            try:
                with open(OUTBOUNDS_PATH) as f:
                    existing = json.loads(f.read())
                if existing == outbounds_config:
                    print("Outbounds unchanged, skipping update")
                    sys.exit(0)
            except Exception:
                pass  # If we can't read/parse existing, just replace it

        # Write candidate to temp file and validate with sing-box check
        fd, tmp_path = tempfile.mkstemp(suffix=".json", dir="/var/lib/sing-box")
        try:
            with os.fdopen(fd, "w") as f:
                f.write(candidate_json)

            result = subprocess.run(
                [SING_BOX, "check", "-c", STATIC_CONFIG, "-c", tmp_path],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode != 0:
                print(f"Error: sing-box config validation failed:\n{result.stderr}", file=sys.stderr)
                os.unlink(tmp_path)
                sys.exit(1)
        except Exception as e:
            print(f"Error during validation: {e}", file=sys.stderr)
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
            sys.exit(1)

        # Atomically replace outbounds.json
        os.rename(tmp_path, OUTBOUNDS_PATH)
        print(f"Updated outbounds.json with {len(proxy_outbounds)} proxy outbound(s)")

        # Restart sing-box to pick up new outbounds
        result = subprocess.run(
            [SYSTEMCTL, "try-restart", "sing-box-proxy.service"],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            print(f"Warning: failed to restart sing-box-proxy: {result.stderr}", file=sys.stderr)
        else:
            print("sing-box-proxy restarted successfully")

    if __name__ == "__main__":
        main()
  '';

  # TUI selector script for switching proxy chains via Clash API
  selectorScript = pkgs.writeShellApplication {
    name = "sing-box-select";
    runtimeInputs = [ pkgs.curl pkgs.jq pkgs.fzf ];
    text = ''
      API="http://127.0.0.1:${toString cfg.clashApiPort}"
      SELECTOR="proxy"
      data=$(curl -s "$API/proxies/$SELECTOR")
      current=$(echo "$data" | jq -r '.now')
      outbounds=$(echo "$data" | jq -r '.all[]')
      selected=$(echo "$outbounds" | fzf --header="Current: $current" --prompt="Select chain> ")
      if [ -n "$selected" ]; then
        curl -s -X PUT "$API/proxies/$SELECTOR" \
          -H 'Content-Type: application/json' \
          -d "$(jq -n --arg name "$selected" '{name: $name}')"
        echo "Switched to: $selected"
      fi
    '';
  };

in {
  options.custom.services.proxy = {
    enable = lib.mkEnableOption "sing-box proxy service";

    subscriptionUpdateInterval = lib.mkOption {
      type = lib.types.str;
      default = "30min";
      description = "How often to fetch subscription updates";
    };

    clashApiPort = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Port for Clash API (chain selector UI)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Force resolv.conf to use sing-box's local DNS listener
    # This bypasses resolvconf/DHCP overrides entirely
    environment.etc."resolv.conf".text = lib.mkForce ''
      nameserver 127.0.0.1
      options ndots:0 timeout:1 edns0
    '';

    # Static sing-box config (inbounds, DNS, routes — no proxy outbounds)
    environment.etc."sing-box/config.json".source = staticConfigFile;

    # SOPS secret — subscription URL (not the full config anymore)
    sops.secrets."sing-box-sub-url" = {
      sopsFile = ../../../secrets/sing-box-sub-url;
      format = "binary";
      mode = "0400";
    };

    # sing-box package + TUI selector
    environment.systemPackages = [
      pkgs.sing-box
      selectorScript
    ];

    # Main sing-box proxy service — reads static config + dynamic outbounds
    systemd.services.sing-box-proxy = {
      description = "sing-box Proxy Service";
      after = [ "network-online.target" "sing-box-fetch-subscription.service" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.sing-box}/bin/sing-box run -c /etc/sing-box/config.json -c /var/lib/sing-box/outbounds.json";
        Restart = "on-failure";
        RestartSec = 5;

        # Security hardening
        DynamicUser = false; # Need root for TUN
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

    # Subscription fetcher — oneshot service that updates outbounds.json
    systemd.services.sing-box-fetch-subscription = {
      description = "Fetch sing-box subscription outbounds";
      after = [ "network-online.target" "sops-nix.service" ];
      wants = [ "network-online.target" ];
      before = [ "sing-box-proxy.service" ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${fetcherScript}/bin/sing-box-fetch-subscription";
        StateDirectory = "sing-box";
        PrivateTmp = true;
      };
    };

    # Timer for periodic subscription updates
    systemd.timers.sing-box-fetch-subscription = {
      description = "Periodically fetch sing-box subscription updates";
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "1min";
        OnUnitActiveSec = cfg.subscriptionUpdateInterval;
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
