# GUI applications
{ config, pkgs, inputs, lib, ... }:

let
  # Upstream claude-desktop-linux-flake still references `nodePackages.asar`,
  # which was removed from nixpkgs on 2026-03-03. Override the auto-supplied
  # `nodePackages` arg to point its `.asar` lookup at the new top-level `asar`
  # package. Drop this override once the upstream flake is updated.
  claude-desktop = inputs.claude-desktop.packages.x86_64-linux.claude-desktop.override {
    nodePackages = { inherit (pkgs) asar; };
  };
in
{
  home.packages = with pkgs; [
    telegram-desktop
    ayugram-desktop
    google-chrome
    claude-desktop
    spotify
    zoom-us
    loupe
    obsidian
  ];
}
