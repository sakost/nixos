# Codex is installed and updated by the official standalone installer:
#   curl -fsSL https://chatgpt.com/codex/install.sh | sh
# Remote control requires ~/.codex/packages/standalone/current/codex.
# Leave ~/.local/bin/codex owned by the installer, not Home Manager.
# ~/.local/bin is already on PATH via home/xdg.nix.
{ ... }:
{
  programs.codex.enable = false;
}
