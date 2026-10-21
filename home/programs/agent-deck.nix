# agent-deck — session manager for AI coding agents, plus its web UI as a
# systemd user service reachable over the tailnet.
#
# Its config is a plain, hand-editable ~/.config/agent-deck/config.toml (not
# Nix-managed, so the TUI settings panel can save to it). Accounts live under
# ~/.agent-deck/<account>/{claude,codex}.
#
# The UI listens on :8420 on all interfaces, but the firewall only admits
# tailscale0 (modules/services/tailscale.nix trusts it), so it is tailnet-only.
# Open http://sakost-pc:8420 (MagicDNS) and paste the token printed by
#   cat ~/.local/state/agent-deck/web-token
# The token is generated on first start and kept out of argv via -token-file.
{ pkgs, ... }:

let
  agentDeck = pkgs.callPackage ../../packages/agent-deck.nix { };

  tokenFile = "%S/agent-deck/web-token";

  ensureToken = pkgs.writeShellScript "agent-deck-web-token" ''
    f="$STATE_DIRECTORY/web-token"
    if [ ! -s "$f" ]; then
      umask 077
      ${pkgs.openssl}/bin/openssl rand -hex 32 > "$f"
    fi
  '';
in
{
  home.packages = [ agentDeck ];

  systemd.user.services.agent-deck-web = {
    Unit.Description = "agent-deck web UI (tailnet)";

    Service = {
      Type = "simple";
      StateDirectory = "agent-deck";
      ExecStartPre = ensureToken;
      ExecStart = builtins.concatStringsSep " " [
        "${agentDeck}/bin/agent-deck web --no-tui"
        "--listen 0.0.0.0:8420"
        "--token-file ${tokenFile}"
        # Host header checks: MagicDNS short and full names, tailnet IP.
        "--allowed-host sakost-pc"
        "--allowed-host sakost-pc.tail4c14c7.ts.net"
        "--allowed-host 100.110.59.31"
      ];
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
