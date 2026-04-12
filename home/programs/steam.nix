# Steam user-level gaming utilities
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mangohud
    protonup-qt
  ];
}
