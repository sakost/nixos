# OpenAI Codex — lightweight coding agent that runs in the terminal.
# Auth is interactive: run `codex login` once; the session is stored under
# CODEX_HOME (~/.codex by default since home.preferXdgDirectories is unset).
{ pkgs, ... }:

let
  codexPackage = pkgs.callPackage ../../packages/codex.nix {
    upstreamCodex = pkgs.codex;
  };
in
{
  # The integrated NixOS user profile is only replaced by a system switch.
  # Keep the selected Home Manager package immediately reachable on the
  # existing user-local PATH as well.
  home.file.".local/bin/codex".source = "${codexPackage}/bin/codex";

  programs.codex = {
    enable = true;
    package = codexPackage;
  };
}
