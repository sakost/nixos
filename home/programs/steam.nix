# Steam user-level gaming utilities
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mangohud
    gamescope
    protonup-qt
  ];
}
