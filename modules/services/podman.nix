# Podman container runtime (rootless + rootful)
{ config, pkgs, ... }:

{
  # Native overlayfs for podman (much faster than fuse-overlayfs)
  boot.kernelModules = [ "overlay" ];

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Enable rootful Podman via socket
  virtualisation.containers.enable = true;
  virtualisation.containers.containersConf.settings = {
    engine = {
      compose_warning_logs = false;
    };
  };

  # Podman-compose and tools
  environment.systemPackages = with pkgs; [
    podman-compose
    fuse-overlayfs
  ];
}
