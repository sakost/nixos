# Services modules loader
{ ... }:

{
  imports = [
    ./ssh.nix
    ./networking.nix
    ./podman.nix
    ./snapshots.nix
    ./tailscale.nix
  ];
}
