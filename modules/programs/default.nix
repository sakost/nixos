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
    ./gnome-keyring.nix
    ./cryptopro.nix
    ./virt-manager.nix
    ./veracrypt.nix
    ./plymouth.nix
  ];
}
