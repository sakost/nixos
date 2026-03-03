# onefetch — Git repository info display (like neofetch, but for repos)
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.onefetch ];
}
