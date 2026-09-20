# Services modules loader
{ ... }:

{
  imports = [
    ./ssh.nix
    ./networking.nix
    ./orca.nix
    ./podman.nix
    ./snapshots.nix
    ./tailscale.nix
  ];
}
