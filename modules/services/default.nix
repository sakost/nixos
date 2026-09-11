# Services modules loader
{ ... }:

{
  imports = [
    ./ssh.nix
    ./networking.nix
    ./orca.nix
    ./proxy
    ./podman.nix
    ./snapshots.nix
  ];
}
