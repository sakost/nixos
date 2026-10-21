# agent-deck — session manager for AI coding agents, plus its web UI as a
# systemd user service reachable over the tailnet.
#
# Its config is a plain, hand-editable ~/.config/agent-deck/config.toml (not
# Nix-managed, so the TUI settings panel can save to it). Accounts live under
# ~/.agent-deck/<account>/{claude,codex}.
#
# The UI binds the tailnet address only (not 0.0.0.0) and has NO token: any
# device on the tailnet gets full control of the sessions, so tailscale ACLs
# are the only gate. Open http://sakost-pc:8420 (MagicDNS). The Host-header
# allowlist below still blocks DNS-rebinding from a browser.
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
      # TELEGRAM_BOT_TOKEN etc.; config.toml references them as $VAR so no
      # secret sits in it. Hand-managed, mode 600, never in the store.
      EnvironmentFile = "%h/.agent-deck/secrets.env";
      StandardOutput = "append:%h/.local/share/agent-deck/conductor/bridge.log";
      StandardError = "append:%h/.local/share/agent-deck/conductor/bridge.log";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Periodic check-in message to the `work` conductor. heartbeat.sh is written
  # by `agent-deck conductor setup`, which also emits a unit hardcoding
  # /bin/bash (absent on NixOS, status 203/EXEC); this replaces it.
  systemd.user.services.agent-deck-conductor-heartbeat-work = {
    Unit.Description = "Agent Deck Conductor Heartbeat (work)";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash %h/.local/share/agent-deck/conductor/work/heartbeat.sh";
      WorkingDirectory = "%h";
      Environment = [ "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin" ];
    };
  };

  systemd.user.timers.agent-deck-conductor-heartbeat-work = {
    Unit.Description = "Agent Deck Conductor Heartbeat Timer (work)";
    Timer = {
      OnBootSec = "900s";
      OnUnitActiveSec = "900s";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  # The tmux server (and so every session) dies on reboot, and nothing else
  # revives the conductor until a chat message reaches the bridge. Start it at
  # login/boot; heartbeats and notifications only reach a running conductor.
  systemd.user.services.agent-deck-conductor-autostart = {
    Unit = {
      Description = "Start the agent-deck work conductor";
      After = [ "agent-deck-conductor-bridge.service" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "-${agentDeck}/bin/agent-deck -p ${profile} session start conductor-work";
      Environment = [ "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin" ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.agent-deck-web = {
    Unit = {
      Description = "agent-deck web UI (tailnet)";
      # The bind address only exists once tailscale0 is up; keep retrying
      # instead of tripping the default start-rate limit at boot.
      StartLimitIntervalSec = 0;
    };

    Service = {
      Type = "simple";
      Environment = [ "AGENTDECK_PROFILE=${profile}" ];
      ExecStart = builtins.concatStringsSep " " [
        "${agentDeck}/bin/agent-deck web --no-tui"
        "--listen 100.110.59.31:8420"
        "--insecure-bind" # no token: tailnet-only bind, see header
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
