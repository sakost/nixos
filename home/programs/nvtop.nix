# nvitop — NVIDIA GPU process monitor (interactive TUI)
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.nvitop ];
}
