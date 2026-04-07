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
}
