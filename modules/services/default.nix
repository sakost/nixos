# Services modules loader
{ ... }:

{
  imports = [
    ./ssh.nix
    ./networking.nix
    ./proxy
    ./podman.nix
  ];
}
