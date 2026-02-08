# Podman container runtime (rootless + rootful)
{ config, pkgs, ... }:

{
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Enable rootful Podman via socket
  virtualisation.containers.enable = true;

  # Podman-compose and tools
  environment.systemPackages = with pkgs; [
    podman-compose
    fuse-overlayfs
  ];
}
