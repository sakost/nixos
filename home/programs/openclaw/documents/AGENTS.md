# Agents

## default

A minimal local assistant backed by Ollama running on `127.0.0.1:11434`.
Uses whatever model is set as `agents.defaults.model.primary` in the Nix
config (see `home/programs/openclaw/default.nix`).

Interact via `openclaw agent --message "..."` or the Control UI.
