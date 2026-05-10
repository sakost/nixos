# OpenAI Codex — lightweight coding agent that runs in the terminal.
# Auth is interactive: run `codex login` once; the session is stored under
# CODEX_HOME (~/.codex by default since home.preferXdgDirectories is unset).
{ config, pkgs, ... }:

{
  programs.codex = {
    enable = true;

    settings = {
      # Match the editor used by other CLIs in this config (gh, git).
      preferred_editor = "nvim";
    };
  };
}
