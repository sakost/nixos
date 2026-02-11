# Programs modules loader
{ ... }:

{
  imports = [
    ./zsh.nix
    ./fonts.nix
    ./git.nix
    ./nix-ld.nix
    ./android.nix
    ./steam.nix
  ];
}
