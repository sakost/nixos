# agent-deck — session manager for AI coding agents, plus its web UI as a
# systemd user service reachable over the tailnet.
#
# The UI listens on :8420 on all interfaces, but the firewall only admits
# tailscale0 (modules/services/tailscale.nix trusts it), so it is tailnet-only.
# Open http://sakost-pc:8420 (MagicDNS) and paste the token printed by
#   cat ~/.local/state/agent-deck/web-token
# The token is generated on first start and kept out of argv via -token-file.
{ pkgs, ... }:

let
  agentDeck = pkgs.callPackage ../../packages/agent-deck.nix { };
  toml = pkgs.formats.toml { };

  # Rendered into the (read-only) store, so nothing with a secret goes here:
  # keyed MCPs (tavily, context7, memory) stay in Claude/Codex's own configs.
  # TUI Settings-panel (`S`) edits cannot persist; change this file instead.
  config = {
    default_tool = "claude";
    # Don't let agents rename sessions behind your back.
    sync_title = false;

    # Sessions are spawned by a systemd user unit with a bare environment;
    # run them through an interactive shell so PATH (~/.local/bin for codex,
    # cargo bin, nix profile) and the sessionVariables are present.
    shell.launch_shell = true;

    # Own tmux server: agent-deck's global options/bindings don't leak into
    # the personal tmux (home/programs/tmux.nix).
    tmux = {
      socket_name = "agent-deck";
      options.history-limit = "50000";
    };

    # Accounts. The default profile uses ~/.claude and ~/.codex. Add another
    # account as [profiles.<name>.claude].config_dir (+ `CLAUDE_CONFIG_DIR=… claude`
    # to log in), then `agent-deck -p <name>`.
    claude.allow_dangerous_mode = true;
    codex.yolo_mode = false;

    # The binary is a read-only store path: updates come from the flake.
    updates = {
      auto_update = false;
      auto_install = false;
      auto_restart = false;
      check_enabled = false;
      manage_timer = false;
      auto_update_remotes = false;
    };

    # Search across Claude and Codex transcripts.
    recall.enabled = true;

    web.mutations_enabled = true;
    worktree.run_repo_scripts = "prompt";

    mcp_pool = {
      enabled = true;
      pool_all = true;
      # cwd- or browser-bound: one instance per session.
      exclude_mcps = [ "serena" "playwright" "chrome-devtools" ];
    };

    mcps = {
      gitmcp = {
        url = "https://gitmcp.io/docs";
        transport = "http";
        description = "Docs/code of any GitHub repo (GitMCP)";
      };
      sequential-thinking = {
        command = "pnpm";
        args = [ "dlx" "@modelcontextprotocol/server-sequential-thinking" ];
        description = "Step-by-step reasoning";
      };
      serena = {
        command = "uvx";
        args = [
          "--from" "git+https://github.com/oraios/serena" "serena" "start-mcp-server"
          "--context" "ide-assistant" "--enable-web-dashboard" "false"
          "--enable-gui-log-window" "false" "--project" "."
        ];
        description = "Symbolic code navigation";
      };
      playwright = {
        command = "pnpm";
        args = [ "dlx" "@playwright/mcp@latest" ];
        description = "Browser automation";
      };
      chrome-devtools = {
        command = "pnpm";
        args = [ "dlx" "chrome-devtools-mcp@latest" ];
        description = "Chrome DevTools";
      };
      glab = {
        command = "glab";
        args = [ "mcp" "serve" ];
        description = "GitLab CLI";
      };
    };
  };

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

  xdg.configFile."agent-deck/config.toml".source = toml.generate "agent-deck-config.toml" config;

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
