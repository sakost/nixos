# OBS Studio configuration
{ config, pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs # Wayland screen capture for Hyprland
      obs-pipewire-audio-capture # PipeWire audio capture
      obs-vkcapture # Vulkan/OpenGL game capture
      obs-backgroundremoval # AI-based background removal
    ];
  };
}
