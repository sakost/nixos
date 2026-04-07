# OpenClaw — personal AI assistant gateway, wired to local Ollama.
#
# Upstream:            https://github.com/openclaw/nix-openclaw
# Ollama provider:     https://docs.openclaw.ai/providers/ollama
{ config, lib, pkgs, inputs, osConfig, ... }:

let
  # Default Ollama model. OpenClaw resolves this as `ollama/<tag>`.
  # Swap for any tag you have locally — run `ollama list` to see them.
  # Gemma 4 variants on ollama.com: e2b (7.2 GB), e4b (~9.6 GB),
  # 26b (18 GB MoE), 31b (20 GB dense). `:latest` doesn't exist.
  defaultModel = "gemma4:e4b";

  # Path to the sops-decrypted env file. Declared in
  # hosts/sakost-pc/default.nix as sops.secrets."openclaw-env".
  # osConfig exposes the NixOS-level sops config from inside home-manager.
  openclawEnvFile = osConfig.sops.secrets."openclaw-env".path;

  # Shared per-instance config. Every OpenClaw instance needs its own
  # copy because the config MUST live under instances.<name>.config,
  # NOT under programs.openclaw.config — see the long comment below.
  sharedInstanceConfig = {
    gateway.mode = "local";

    # Native Ollama /api/chat endpoint. Do NOT add /v1 to baseUrl —
    # the OpenAI-compat path breaks tool calling upstream.
    models.providers.ollama = {
      apiKey  = "ollama-local";
      baseUrl = "http://127.0.0.1:11434";
      api     = "ollama";
    };

    agents.defaults.model.primary = "ollama/${defaultModel}";

    # auth.token is deliberately unset. OpenClaw reads
    # OPENCLAW_GATEWAY_TOKEN from EnvironmentFile (see
    # src/infra/dotenv.ts upstream) and that value takes precedence.
  };
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

    # IMPORTANT: do NOT set `programs.openclaw.config = { ... }` here.
    # nix-openclaw's config merge in config.nix is:
    #   mergedConfig0 = stripNulls (recursiveUpdate
    #     (recursiveUpdate baseConfig cfg.config)
    #     inst.config)
    # and `inst.config` evaluates to an attrset where every top-level
    # key is `null` (schema default: `mkOption { type = nullOr (...);
    # default = null; }`). recursiveUpdate's rule "if either side isn't
    # an attrset, rhs wins" means the null-valued `inst.config.gateway`
    # clobbers whatever `cfg.config.gateway` contributed. stripNulls
    # then deletes the empty shell and you end up with a JSON file
    # containing *only* `agents.defaults.workspace` (which is grafted
    # on AFTER stripNulls by the `pinAgentDefaults` logic).
    #
    # The fix is to attach config directly to the instance so there is
    # only one layer that sees real values, not two competing layers.

    instances = {
      # Main always-on assistant: uses the default state dir
      # (~/.openclaw) and port 18789 (nix-openclaw's default).
      default = {
        enable = true;
        config = sharedInstanceConfig;
      };

      # Dedicated instance for drafting programming-language articles.
      # Lives in ~/.openclaw-articles/workspace so its memory, skills,
      # and git-tracked notes stay isolated from the main assistant.
      # Runs on port 18790 when started and is NOT auto-started at
      # login — launch on demand with
      #   `systemctl --user start openclaw-gateway-articles`
      # (stopped by nix-openclaw's default `Install = {}` absence).
      articles = {
        enable = true;
        stateDir = "${config.home.homeDirectory}/.openclaw-articles";
        gatewayPort = 18790;
        config = sharedInstanceConfig;
      };
    };
  };

  # Inject the sops-decrypted env file into BOTH gateway units. mkAfter
  # preserves whatever EnvironmentFile nix-openclaw may already set.
  # Both instances share the same OPENCLAW_GATEWAY_TOKEN — the token
  # authenticates CLI clients to the gateway, not the model provider.
  systemd.user.services.openclaw-gateway.Service.EnvironmentFile =
    lib.mkAfter [ openclawEnvFile ];
  systemd.user.services.openclaw-gateway-articles.Service.EnvironmentFile =
    lib.mkAfter [ openclawEnvFile ];

  # Default instance auto-starts on user login. Upstream nix-openclaw
  # defines Unit + Service but no Install section, so nothing would
  # wire `systemctl --user enable` to a target. We add it here.
  # The articles instance deliberately has NO Install section so it
  # stays stopped by default — start it by hand when you need it.
  systemd.user.services.openclaw-gateway.Install.WantedBy = [ "default.target" ];

  # Tell OpenClaw it's managed by Nix so its interactive self-updater
  # (triggered by `ollama launch openclaw` and similar) doesn't try to
  # `npm install -g openclaw@latest` into ~/.local/share/npm. The
  # systemd units already set this in their Environment=, but that only
  # applies to the daemon, not to shell invocations of the `openclaw`
  # CLI. This puts the var in every login shell's environment.
  home.sessionVariables.OPENCLAW_NIX_MODE = "1";
}
