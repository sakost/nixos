# sing-box Remote Profiles & Chain Selector

## Summary

Replace the monolithic SOPS-encrypted sing-box config with a split architecture: Nix-generated static config (DNS, TUN, routes, Clash API) + dynamically fetched outbounds from a Remnawave panel subscription. Add chain selection via Clash API web UI (Yacd-meta) and a TUI script.

## Goals

1. Auto-fetch outbound profiles from Remnawave subscription URL (SFA user-agent → sing-box JSON)
2. Periodically update (default 30min) without restart if config unchanged
3. Keep local config (DNS, TUN, routing, rule_sets) declarative in Nix
4. Enable manual chain selection via browser GUI (Yacd-meta) and terminal TUI (fzf)
5. Reduce secret surface from ~4KB encrypted blob to ~100B subscription URL

## Architecture

### Config split

sing-box is started with two config files merged via multiple `-c` flags:

```
sing-box run -c /etc/sing-box/config.json -c /var/lib/sing-box/outbounds.json
```

sing-box merges configs by top-level key — arrays like `outbounds` get concatenated. Duplicate outbound tags cause a fatal error, so each tag must appear in exactly one file.

**File 1: `/etc/sing-box/config.json`** (Nix-managed via `environment.etc`, read-only)
- `log`: level warn, timestamps
- `dns`: google (8.8.8.8) + yandex (77.88.8.8), RU domains → local, strategy ipv4_only
- `inbounds`: TUN (sing-tun, 172.19.0.1/30, mtu 1492, mixed stack) + DNS listener (127.0.0.1:53 UDP)
- `outbounds`: `direct` (tag: `direct`) and `block` (tag: `block`) — these are static and referenced by route rules
- `route`: sniff, hijack-dns, private IPs direct, .local/.lan/.localhost direct, geosite-ru/geoip-ru direct, ads blocked, final → `proxy`
- `route.rule_set`: geosite-category-ru, geoip-ru, geosite-category-ads-all (remote binary, download via direct)
- `experimental.cache_file`: enabled, path `/var/lib/sing-box/cache.db` (absolute path, within StateDirectory; persists selector choice across restarts)
- `experimental.clash_api`: external_controller 127.0.0.1:9090, external_ui `/var/lib/sing-box/ui` (absolute path, within StateDirectory), external_ui_download_url `https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip`, external_ui_download_detour `direct`

**File 2: `/var/lib/sing-box/outbounds.json`** (fetcher-managed)
- `outbounds` array containing:
  - `selector` (tag: `proxy`) — lists `auto` + all fetched chain tags. `interrupt_exist_connections: true`
  - `urltest` (tag: `auto`) — lists all fetched chain tags, url check every 5min
  - All VLESS outbounds from subscription (original tags preserved, e.g., "VK Moscow & Amsterdam", "Austria", etc.)

Note: `direct` and `block` are NOT in this file — they live in the static config to avoid duplicate tag errors.

**Contract between files**: Route config references tags `proxy`, `direct`, `block`. `direct` and `block` are in File 1. `proxy` is in File 2.

### Fetcher script

A Python script (`sing-box-fetch-subscription`) that runs as a systemd service triggered by a timer.

**Inputs**:
- Subscription URL read from sops secret file at runtime
- User-agent: `SFA` (returns sing-box JSON format from Remnawave)

**Logic**:
1. Read subscription URL from sops secret path (stripped of whitespace/newlines)
2. HTTP GET with `SFA` user-agent, using explicit DNS resolver `8.8.8.8` to avoid chicken-and-egg problem (system DNS points to sing-box which may not be running yet)
3. Parse JSON response, extract outbound entries (filter: keep types `vless`, `vmess`, `trojan`, `shadowsocks`, `hysteria`, `hysteria2`, `tuic`, `wireguard`, `ssh`; discard `selector`, `urltest`, `direct`, `block`, `dns`)
4. Collect extracted outbound tags
5. Build outbounds.json:
   ```json
   {
     "outbounds": [
       { "type": "selector", "tag": "proxy",
         "outbounds": ["auto", ...extracted_tags],
         "interrupt_exist_connections": true },
       { "type": "urltest", "tag": "auto",
         "outbounds": [...extracted_tags],
         "url": "http://www.gstatic.com/generate_204",
         "interval": "5m" },
       ...extracted_outbounds
     ]
   }
   ```
6. Write candidate to a temp file, validate with `sing-box check -c /etc/sing-box/config.json -c <tempfile>` — if validation fails, log error and abort
7. Compare validated outbounds.json content with existing file
8. If identical → exit 0, no restart
9. If different → atomically replace file (write to temp + rename), signal systemd to restart sing-box

**Error handling**:
- If fetch fails (network error, non-200, invalid JSON): log error, exit non-zero, do NOT overwrite existing config (stale config is better than no config)
- If subscription returns zero proxy outbounds: log warning, do NOT overwrite (prevents accidental wipe)
- If `sing-box check` fails on new config: log error, do NOT overwrite

### Systemd units

**`sing-box-proxy.service`** (existing, modified):
- ExecStart: `sing-box run -c /etc/sing-box/config.json -c /var/lib/sing-box/outbounds.json`
- Wants: `sing-box-fetch-subscription.service` (ensure first fetch before start)
- After: `sing-box-fetch-subscription.service`
- Rest unchanged (caps, security hardening)

**`sing-box-fetch-subscription.service`** (new, oneshot):
- Type: oneshot
- ExecStart: the fetcher script (runs as root)
- The script handles restart internally: when config changed and validated, it calls `systemctl restart sing-box-proxy.service`. On no change, it exits 0 without restarting.
- After: network-online.target, sops-nix.service
- Before: sing-box-proxy.service (ensures first fetch completes before sing-box starts)
- Wants: network-online.target
- ServiceConfig:
  - ReadWritePaths: `/var/lib/sing-box`
  - PrivateTmp: true

**`sing-box-fetch-subscription.timer`** (new):
- OnBootSec: 1min (give network time to come up; initial fetch is also done via service dependency)
- OnUnitActiveSec: 30min (configurable via module option)
- WantedBy: timers.target (if proxy enabled)

### Chain selector TUI script

A shell script `sing-box-select` installed in PATH:

```bash
#!/usr/bin/env bash
API="http://127.0.0.1:9090"
SELECTOR="proxy"

# Get current outbounds in the selector
data=$(curl -s "$API/proxies/$SELECTOR")
current=$(echo "$data" | jq -r '.now')
outbounds=$(echo "$data" | jq -r '.all[]')

# Pick with fzf, highlighting current
selected=$(echo "$outbounds" | fzf --header="Current: $current" --prompt="Select chain> ")

if [ -n "$selected" ]; then
  curl -s -X PUT "$API/proxies/$SELECTOR" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg name "$selected" '{name: $name}')"
  echo "Switched to: $selected"
fi
```

Dependencies: `curl`, `jq`, `fzf`.

### Web UI

Yacd-meta auto-downloads on first sing-box start via `external_ui_download_url` (`https://github.com/MetaCubeX/Yacd-meta/archive/gh-pages.zip`). Download uses `direct` detour (not proxied via `external_ui_download_detour`). Accessible at `http://127.0.0.1:9090/ui`. Provides:
- Visual chain switcher with latency test buttons
- Connection monitor
- Rule/DNS query viewer

## Nix module interface

```nix
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
```

## Secrets

**Remove**: `secrets/sing-box.json` (the entire sing-box config blob)

**Add**: `secrets/sing-box-sub-url` — plain text file containing just the subscription URL. SOPS-encrypted with same age key.

```yaml
# .sops.yaml addition
- path_regex: secrets/sing-box-sub-url$
  age: age1hctl9v9qq7fcp3qltmxlndhk24d60calvn962ykm4fwkw8d7j4pqushe0g
```

Sops secret in Nix:
```nix
sops.secrets."sing-box-sub-url" = {
  sopsFile = ../../../secrets/sing-box-sub-url;
  format = "binary";
  mode = "0400";
};
```

## File changes

| File | Action |
|------|--------|
| `modules/services/proxy/default.nix` | Rewrite: new module with static config, fetcher, timer, selector script |
| `secrets/sing-box.json` | Delete |
| `secrets/sing-box-sub-url` | Create: SOPS-encrypted subscription URL |
| `.sops.yaml` | Update: change path regex from sing-box.json to sing-box-sub-url |

## Edge cases

- **First boot / no outbounds.json yet**: `sing-box-proxy.service` depends on `sing-box-fetch-subscription.service`, which runs first. If fetch fails on first boot (no network), sing-box won't start. This is acceptable — without outbounds there's nothing to proxy.
- **DNS chicken-and-egg on first boot**: The fetcher uses an explicit DNS resolver (8.8.8.8 via urllib/curl `--resolve` or `--dns-servers`) rather than system DNS, since system DNS points to sing-box which isn't running yet during the fetch.
- **Subscription returns different tags**: The selector adapts automatically. Cache file may reference a now-removed tag — sing-box falls back to the first outbound in the selector list.
- **Clash API access**: Only listens on 127.0.0.1, no auth needed. If exposed externally in the future, add `secret` field.
- **nixos-rebuild with no network**: Same as first boot — fetcher fails, sing-box won't start, system DNS breaks. This matches current behavior (if sops config were broken, same result). Mitigation: the timer retries every 30min.
