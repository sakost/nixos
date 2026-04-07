# OpenClaw — personal AI assistant gateway, wired to local Ollama.
#
# Upstream:            https://github.com/openclaw/nix-openclaw
# Ollama provider:     https://docs.openclaw.ai/providers/ollama
{ config, lib, pkgs, inputs, osConfig, ... }:

let
  # Default Ollama model. OpenClaw resolves this as `ollama/<tag>`.
  # Swap for any tag you have locally — run `ollama list` to see them.
  defaultModel = "gemma4:latest";

  # Path to the sops-decrypted env file. Declared in
  # hosts/sakost-pc/default.nix as sops.secrets."openclaw-env".
  # osConfig exposes the NixOS-level sops config from inside home-manager.
  openclawEnvFile = osConfig.sops.secrets."openclaw-env".path;
in
{
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;
    documents = ./documents;

    bundledPlugins = {
      summarize.enable = true;
    };

    # Community skills installed into each instance's workspace.
    # `copy` mode puts a hashed snapshot of each source tree in the nix
    # store, which home-manager then materializes under
    # ~/.openclaw/workspace/skills/<name>/.
    skills = [
      {
        name = "self-improving-agent";
        description = "Capture learnings, errors, and corrections for continuous agent improvement";
        homepage = "https://github.com/peterskoett/self-improving-agent";
        mode = "copy";
        source = "${inputs.openclaw-skill-self-improving-agent}";
      }
      {
        name = "ontology";
        description = "Typed knowledge graph for structured agent memory and composable skills";
        homepage = "https://clawhub.ai/oswalpalash/ontology";
        mode = "copy";
        source = "${./skills/ontology}";
      }
    ];

    config = {
      gateway = {
        mode = "local";
        # auth.token is deliberately unset. OpenClaw reads
        # OPENCLAW_GATEWAY_TOKEN from EnvironmentFile (see
        # src/infra/dotenv.ts upstream) and that value takes precedence.
      };

      # Native Ollama /api/chat endpoint. Do NOT add /v1 to baseUrl —
      # the OpenAI-compat path breaks tool calling upstream.
      models.providers.ollama = {
        apiKey  = "ollama-local";
        baseUrl = "http://127.0.0.1:11434";
        api     = "ollama";
      };

      agents.defaults.model.primary = "ollama/${defaultModel}";
    };

    instances.default.enable = true;
  };

  # Inject the sops-decrypted env file into the gateway unit. mkAfter
  # preserves whatever EnvironmentFile nix-openclaw may already set.
  systemd.user.services.openclaw-gateway.Service.EnvironmentFile =
    lib.mkAfter [ openclawEnvFile ];

  # Upstream nix-openclaw defines the unit's Unit + Service sections but
  # no Install section, so the service never auto-starts on user login.
  # Hooking it to default.target makes `systemctl --user enable` actually
  # do something, and home-manager's activation wires the enable for us.
  systemd.user.services.openclaw-gateway.Install.WantedBy = [ "default.target" ];

  # Tell OpenClaw it's managed by Nix so its interactive self-updater
  # (triggered by `ollama launch openclaw` and similar) doesn't try to
  # `npm install -g openclaw@latest` into ~/.local/share/npm. The
  # systemd unit already sets this in its Environment=, but that only
  # applies to the daemon, not to shell invocations of the `openclaw`
  # CLI. This puts the var in every login shell's environment.
  home.sessionVariables.OPENCLAW_NIX_MODE = "1";
}
