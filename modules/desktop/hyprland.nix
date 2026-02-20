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
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # XWayland for X11 app compatibility
    programs.xwayland.enable = true;

    # Required services
    services.dbus.enable = true;
    security.polkit.enable = true;

    # GVFS for trash and virtual filesystems in Nautilus
    services.gvfs.enable = true;

    # Elephant — data provider backend required by Walker launcher
    services.elephant.enable = true;

    # Elephant needs sh + user/system binaries in PATH to launch .desktop entries
    systemd.user.services.elephant.serviceConfig.Environment = [
      "PATH=${lib.makeBinPath [ pkgs.bash pkgs.coreutils ]}:/etc/profiles/per-user/%u/bin:/run/current-system/sw/bin"
    ];

    # Wayland packages
    environment.systemPackages = with pkgs; [
      hyprland
      wayland
      xwayland

      # Wayland utilities
      kitty
      swww
      waybar
      satty
      slurp
      grim
      wl-clipboard

      # Desktop utilities
      nautilus
      gvfs # Virtual filesystem (trash, mtp, network shares, etc.)
      mako
      libnotify
      networkmanagerapplet
      brightnessctl
    ];
  };
}
