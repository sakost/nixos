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
{ config, pkgs, ... }:

let
  agentDeck = pkgs.callPackage ../../packages/agent-deck.nix { };

  # `agent-deck conductor setup` wants `pip install toml aiogram`, which does
  # not work on NixOS; run its bridge.py with these libs instead. Telegram
  # only: add slack-bolt / discord-py if a Slack/Discord bridge is enabled.
  bridgePython = pkgs.python3.withPackages (ps: with ps; [ toml aiogram ]);

  # Rendered at build time into fpath (a `source <(...)` would cost every shell start).
  zshCompletion = pkgs.runCommand "agent-deck-zsh-completion" { } ''
    mkdir -p $out/share/zsh/site-functions
    ${agentDeck}/bin/agent-deck completion zsh > $out/share/zsh/site-functions/_agent_deck
  '';

  # The account's conductor and sessions live in this profile, not `default`.
  profile = "me_at_sakost_dev";

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
  home.packages = [ agentDeck zshCompletion ];

  home.sessionVariables.AGENTDECK_PROFILE = profile;

  # Telegram/Slack/Discord bridge to the conductor sessions. bridge.py is
  # installed (and updated) by `agent-deck conductor setup`; bot tokens live in
  # ~/.config/agent-deck/config.toml, never in the store.
  systemd.user.services.agent-deck-conductor-bridge = {
    Unit = {
      Description = "agent-deck conductor bridge";
      After = [ "network-online.target" ];
      ConditionPathExists = "%h/.local/share/agent-deck/conductor/bridge.py";
    };
    Service = {
      Type = "simple";
      ExecStart = "${bridgePython}/bin/python %h/.local/share/agent-deck/conductor/bridge.py";
      WorkingDirectory = "%h";
      Environment = [ "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin" ];
      StandardOutput = "append:%h/.local/share/agent-deck/conductor/bridge.log";
      StandardError = "append:%h/.local/share/agent-deck/conductor/bridge.log";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.agent-deck-web = {
    Unit.Description = "agent-deck web UI (tailnet)";

    Service = {
      Type = "simple";
      StateDirectory = "agent-deck";
      Environment = [ "AGENTDECK_PROFILE=${profile}" ];
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
