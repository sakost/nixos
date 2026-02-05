# Nixvim configuration - Full IDE setup
{ config, pkgs, ... }:

{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./lsp.nix
    ./completion.nix
    ./ui.nix
    ./telescope.nix
    ./git.nix
    ./plugins.nix
  ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
