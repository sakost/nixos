# Hardware modules loader
{ ... }:

{
  imports = [
    ./nvidia.nix
    ./intel-cpu.nix
    ./amd-cpu.nix
    ./audio.nix
    ./bluetooth.nix
    ./mouse.nix
    ./sensors.nix
    ./tpm.nix
  ];
}
