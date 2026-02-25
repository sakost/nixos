# OBS Studio configuration
{ config, pkgs, ... }:

{
  xdg.configFile."obs-studio/.keep".text = "";

  programs.obs-studio = {
    enable = true;

    # Enable CUDA support so autoAddDriverRunpath patches all binaries
    # (including obs-nvenc-test) to find libnvidia-encode.so at runtime.
    package = pkgs.obs-studio.override { cudaSupport = true; };

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs # Wayland screen capture for Hyprland
      obs-pipewire-audio-capture # PipeWire audio capture
      obs-vkcapture # Vulkan/OpenGL game capture
      obs-backgroundremoval # AI-based background removal
    ];
  };
}
