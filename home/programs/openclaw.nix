# OpenClaw — self-hosted AI assistant/agent gateway
{ config, pkgs, lib, ... }:

let
  configDir = "${config.xdg.configHome}/openclaw";
  stateDir = "${config.xdg.dataHome}/openclaw";

  # Declarative config (secret-free — tokens come from EnvironmentFile)
  configFile = builtins.toJSON {
    agents.defaults = {
      model.primary = "anthropic/claude-haiku-4-5";
      models."anthropic/claude-haiku-4-5" = {};
      workspace = "/home/sakost/.openclaw/workspace";
    };
    commands = {
      native = "auto";
      nativeSkills = "auto";
      restart = true;
      ownerDisplay = "raw";
    };
    session.dmScope = "per-channel-peer";
    hooks.internal = {
      enabled = true;
      entries = {
        boot-md.enabled = true;
        bootstrap-extra-files.enabled = true;
        command-logger.enabled = true;
        session-memory.enabled = true;
      };
    };
    channels.telegram = {
      enabled = true;
      dmPolicy = "pairing";
      groupPolicy = "allowlist";
      streaming = "off";
      # botToken loaded from TELEGRAM_BOT_TOKEN env var
    };
    gateway = {
      port = 9001;
      mode = "local";
      bind = "loopback";
      auth.mode = "token";
      # auth.token loaded from OPENCLAW_GATEWAY_TOKEN env var
      tailscale = {
        mode = "off";
        resetOnExit = false;
      };
    };
    skills.install.nodeManager = "bun";
    plugins.entries.telegram.enabled = true;
  };
in
{
  home.packages = [ pkgs.openclaw ];

  # Zsh completions (source after compinit since the script uses compdef directly)
  programs.zsh.initContent = let
    completions = pkgs.runCommand "openclaw-zsh-completions" {
      nativeBuildInputs = [ pkgs.openclaw ];
    } ''
      openclaw completion > $out
    '';
  in ''
    source ${completions}
  '';

  # Config file (no secrets — tokens are injected via env vars)
  xdg.configFile."openclaw/config.json" = {
    text = configFile;
    force = true;
  };

  # Environment variables for openclaw
  home.sessionVariables = {
    OPENCLAW_CONFIG_PATH = "${configDir}/config.json";
    OPENCLAW_STATE_DIR = stateDir;
  };

  # Systemd user service for the gateway
  # Secrets (ANTHROPIC_API_KEY, TELEGRAM_BOT_TOKEN, OPENCLAW_GATEWAY_TOKEN)
  # are injected via EnvironmentFile from sops-nix
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "OpenClaw Gateway";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.openclaw} gateway";
      Restart = "on-failure";
      RestartSec = 5;
      EnvironmentFile = "/run/secrets/openclaw-env";
      Environment = [
        "OPENCLAW_CONFIG_PATH=${configDir}/config.json"
        "OPENCLAW_STATE_DIR=${stateDir}"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  # Desktop entry
  xdg.desktopEntries.openclaw = {
    name = "OpenClaw";
    comment = "Open OpenClaw Dashboard";
    exec = "${lib.getExe pkgs.openclaw} dashboard";
    terminal = false;
    categories = [ "Utility" ];
  };

  # Hyprland keybinding: SUPER+SHIFT+O opens dashboard
  wayland.windowManager.hyprland.settings.bind = [
    "SUPER SHIFT, O, exec, uwsm app -- ${lib.getExe pkgs.openclaw} dashboard"
  ];
}
