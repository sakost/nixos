# Nvidia GPU configuration module
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.nvidia;
in {
  options.custom.hardware.nvidia = {
    enable = lib.mkEnableOption "Nvidia GPU support";
  };

  config = lib.mkIf cfg.enable {
    # X server video driver (required even for Wayland)
    services.xserver.enable = true;
    services.xserver.videoDrivers = [ "nvidia" ];

    # Disable GDM (we use greetd)
    services.displayManager.gdm.enable = false;

    # Nvidia driver configuration
    hardware.nvidia = {
      modesetting.enable = true;
      open = false;  # Use proprietary driver
      nvidiaSettings = true;
      # 610.57.04. Was pinned to legacy_580 to dodge the Xid 109 CTX SWITCH
      # TIMEOUT / GSP firmware bug in 595.58.03 (NVIDIA #5052028); 610.x is two
      # branches past that. If Xid 109 returns under gamescope, check
      # `dmesg | grep Xid` and fall back to nvidiaPackages.legacy_580.
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };

    # Graphics acceleration
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;

    # NVIDIA Container Toolkit — enables GPU access in containers (Docker/Podman)
    hardware.nvidia-container-toolkit.enable = true;

    # Driver updates load new userspace libraries during switch, but the old
    # kernel module stays loaded until reboot. Restarting the CDI generator in
    # that window fails with "Driver/library version mismatch".
    systemd.services.nvidia-container-toolkit-cdi-generator.restartIfChanged = false;
  };
}
