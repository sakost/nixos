# Nixvim configuration - Full IDE setup
{ config, pkgs, lib, osConfig ? null, ... }:

let
  isServer = osConfig.custom.profiles.server.enable or false;
in {
  imports = [
    ./options.nix
    ./keymaps.nix
    ./lsp.nix
    ./completion.nix
    ./ui.nix
    ./telescope.nix
    ./git.nix
    ./plugins.nix
    ./dadbod.nix
    ./cmake.nix
    ./dap.nix
  ] ++ lib.optionals (!isServer) [
    ./ai-completion.nix
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
