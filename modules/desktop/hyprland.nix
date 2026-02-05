# Hyprland compositor configuration module (system-level)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop.hyprland;
in {
  options.custom.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland Wayland compositor";
  };

  config = lib.mkIf cfg.enable {
    # Enable Hyprland
    programs.hyprland.enable = true;

    # XWayland for X11 app compatibility
    programs.xwayland.enable = true;

    # Required services
    services.dbus.enable = true;
    security.polkit.enable = true;

    # Wayland packages
    environment.systemPackages = with pkgs; [
      hyprland
      wayland
      xwayland

      # Wayland utilities
      kitty
      swww
      rofi
      waybar
      swappy
      slurp
      grim
      wl-clipboard
      cliphist

      # Desktop utilities
      nautilus
      dunst
      libnotify
      networkmanagerapplet
      brightnessctl
    ];
  };
}
