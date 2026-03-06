# OpenClaw — self-hosted AI assistant/agent gateway
{ config, pkgs, lib, ... }:

let
  configDir = "${config.xdg.configHome}/openclaw";
  stateDir = "${config.xdg.dataHome}/openclaw";
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

  # Config file managed declaratively
  xdg.configFile."openclaw/config.json".force = true;
  xdg.configFile."openclaw/config.json".text = builtins.toJSON {
    gateway = {
      mode = "local";
      port = 9001;
    };
  };

  # Environment variables for openclaw
  home.sessionVariables = {
    OPENCLAW_CONFIG_PATH = "${configDir}/config.json";
    OPENCLAW_STATE_DIR = stateDir;
  };

  # Systemd user service for the gateway
  systemd.user.services.openclaw-gateway = {
    Unit = {
      Description = "OpenClaw Gateway";
      After = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.openclaw} gateway --allow-unconfigured";
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
