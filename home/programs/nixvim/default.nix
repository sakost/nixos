# Nixvim configuration - Full IDE setup
{ config, pkgs, ... }:

{
  imports = [
    ./options.nix
    ./keymaps.nix
    ./lsp.nix
    ./completion.nix
    ./ai-completion.nix
    ./ui.nix
    ./telescope.nix
    ./git.nix
    ./plugins.nix
    ./dadbod.nix
    ./cmake.nix
    ./dap.nix
  ];

  programs.nixvim = {
    enable = true;
    # Match nixvim's nixpkgs to the one home-manager uses (useGlobalPkgs)
    nixpkgs.source = pkgs.path;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };
}
