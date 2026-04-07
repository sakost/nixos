# OpenClaw — personal AI assistant gateway, wired to local Ollama.
#
# Single gateway with multiple isolated agents (default + articles),
# each with its own workspace, agentDir, and session store. See
# https://docs.openclaw.ai/concepts/multi-agent for the model.
#
# Upstream:            https://github.com/openclaw/nix-openclaw
# Ollama provider:     https://docs.openclaw.ai/providers/ollama
# Multi-agent docs:    https://docs.openclaw.ai/concepts/multi-agent
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

  # Per-agent workspace directories. OpenClaw's convention for non-default
  # agents is `~/.openclaw/workspace-<id>`, mirroring how OPENCLAW_PROFILE
  # would name them. Each workspace is fully isolated from the others —
  # separate AGENTS.md/SOUL.md/TOOLS.md, separate session memory, separate
  # local notes. The agents share the gateway, the model provider, and
  # the auth token, but nothing else.
  workspaceMain     = "${config.home.homeDirectory}/.openclaw/workspace";
  workspaceArticles = "${config.home.homeDirectory}/.openclaw/workspace-articles";
in
{
  imports = [ inputs.nix-openclaw.homeManagerModules.openclaw ];

  programs.openclaw = {
    enable = true;

    # documents is deliberately NOT set here. nix-openclaw's default
    # behavior installs AGENTS.md/SOUL.md/TOOLS.md into the workspace
    # as symlinks into /nix/store, which OpenClaw's gateway rejects
    # with `GatewayRequestError: unsafe workspace file ... Symlink
    # escapes workspace root`. The custom activation script below
    # (openclawCopyDocuments) installs them as regular files instead,
    # so they live inside the workspace root and pass the sandbox check.
    # documents = null;  (implicit default)

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
    # key is `null` (schema default). recursiveUpdate's "non-attrset
    # wins" rule means the null-valued inst.config keys clobber whatever
    # cfg.config contributed. Attach config to instances.<name>.config
    # instead so there's only one layer that sees real values.

    instances.default = {
      enable = true;
      config = {
        gateway.mode = "local";

        # Native Ollama /api/chat endpoint. Do NOT add /v1 to baseUrl —
        # the OpenAI-compat path breaks tool calling upstream.
        models.providers.ollama = {
          apiKey  = "ollama-local";
          baseUrl = "http://127.0.0.1:11434";
          api     = "ollama";
        };

        agents = {
          # Inherited by all agents in `list` unless overridden per-agent.
          defaults.model.primary = "ollama/${defaultModel}";

          # Multi-agent configuration: a single gateway hosts both
          # `main` and `articles` simultaneously. Each agent gets its
          # own workspace tree, agentDir (auth profiles + sessions),
          # and AGENTS.md/SOUL.md/TOOLS.md. Visible side-by-side in the
          # Control UI's agent dropdown. The `id` is the routing key.
          # See https://docs.openclaw.ai/concepts/multi-agent
          list = [
            {
              id = "main";
              workspace = workspaceMain;
            }
            {
              id = "articles";
              workspace = workspaceArticles;
            }
          ];
        };

        # auth.token is deliberately unset. OpenClaw reads
        # OPENCLAW_GATEWAY_TOKEN from EnvironmentFile (see
        # src/infra/dotenv.ts upstream) and that value takes precedence.
      };
    };
  };

  # Copy AGENTS.md / SOUL.md / TOOLS.md as REGULAR files into BOTH agent
  # workspaces. nix-openclaw's standard documents mechanism uses symlinks
  # into /nix/store which OpenClaw's gateway rejects with "Symlink
  # escapes workspace root". `install` creates a regular file under the
  # workspace, so the target == the file itself and the sandbox check
  # passes. Runs after openclawDirs so the workspace dirs already exist.
  home.activation.openclawCopyDocuments = lib.hm.dag.entryAfter [ "openclawDirs" ] ''
    for ws in "${workspaceMain}" "${workspaceArticles}"; do
      run --quiet ${lib.getExe' pkgs.coreutils "mkdir"} -p "$ws"
      for f in AGENTS.md SOUL.md TOOLS.md; do
        # install(1) atomically replaces the destination — handles
        # both "doesn't exist" and "was a symlink from a previous
        # rebuild" cases without the rm-then-cp dance.
        run --quiet ${lib.getExe' pkgs.coreutils "install"} -m 644 \
          "${./documents}/$f" "$ws/$f"
      done
    done
  '';

  # Force home-manager to overwrite the openclaw config file on every
  # activation. nix-openclaw's custom `openclawConfigFiles` activation
  # script runs `ln -sfn ${configFile} ${configPath}` AFTER home-manager's
  # linkGeneration, pointing the symlink at a different store path than
  # home-manager's tree. Without `force = true`, the next rebuild sees a
  # foreign symlink and either errors or backs it up. force=true
  # unconditionally overwrites and avoids the dance.
  home.file.".openclaw/openclaw.json".force = true;

  # Inject the sops-decrypted env file into the gateway unit. mkAfter
  # preserves whatever EnvironmentFile nix-openclaw may already set.
  systemd.user.services.openclaw-gateway.Service.EnvironmentFile =
    lib.mkAfter [ openclawEnvFile ];

  # Auto-start the gateway on user login. Upstream nix-openclaw defines
  # Unit + Service but no Install section, so nothing would wire
  # `systemctl --user enable` to a target without this.
  systemd.user.services.openclaw-gateway.Install.WantedBy = [ "default.target" ];

  # Tell OpenClaw it's managed by Nix so its interactive self-updater
  # (triggered by `ollama launch openclaw` and similar) doesn't try to
  # `npm install -g openclaw@latest` into ~/.local/share/npm. The
  # systemd unit already sets this in its Environment=, but that only
  # applies to the daemon, not to shell invocations of the `openclaw`
  # CLI. This puts the var in every login shell's environment.
  home.sessionVariables.OPENCLAW_NIX_MODE = "1";
}
