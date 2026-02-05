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
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    # Graphics acceleration
    hardware.graphics.enable = true;
    hardware.graphics.enable32Bit = true;
  };
}
