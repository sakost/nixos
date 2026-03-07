# Hyprland user configuration — main entry point
{ config, pkgs, theme, ... }:

let
  c = theme.colors;
  # Hyprland uses rgba(RRGGBBaa) format — strip # and append alpha hex
  hyprRgba = color: alpha: "rgba(${builtins.substring 1 6 color}${alpha})";
in
{
  imports = [
    ./animations.nix
    ./keybindings.nix
    ./rules.nix
    ./scripts.nix
    ./autostart.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = false; # Managed by UWSM instead

    plugins = [
      pkgs.hyprlandPlugins.hyprsplit
      # hyprspace is broken with Hyprland 0.53.3 (LOG -> Log rename)
      # TODO: re-enable once nixpkgs updates hyprspace
      # pkgs.hyprlandPlugins.hyprspace
      pkgs.hyprlandPlugins.hyprwinwrap
    ];

    settings = {
      # Monitor setup - customize per host if needed
      monitor = [
        "DP-2,3840x2160@144,0x0,1.5,bitdepth,10,cm,hdr,sdrbrightness,1.2,sdrsaturation,1.05"
        "HDMI-A-1,1920x1080@60,2560x0,1.0"
      ];

      render = {
        cm_fs_passthrough = true;
      };

      quirks = {
        prefer_hdr = true;
      };

      # Environment variables
      env = [
        "XCURSOR_SIZE,32"
        "HYPRCURSOR_SIZE,32"
        # Nvidia specific
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
        "__GL_VRR_ALLOWED,1"
        # GTK4 4.20+ renamed ngl->gl; needed for walker and other GTK4 apps on Nvidia
        "GSK_RENDERER,gl"
        # Java/Swing apps (Android Studio, JetBrains IDEs)
        "_JAVA_AWT_WM_NONREPARENTING,1"
      ];

      # Programs
      "$terminal" = "uwsm app -- alacritty";
      "$fileManager" = "uwsm app -- nautilus";
      "$menu" = "walker";

      # General
      general = {
        gaps_in = 4;
        gaps_out = 8;
        border_size = 2;
        "col.active_border" = "${hyprRgba c.accent "cc"} ${hyprRgba c.magenta "99"} 45deg";
        "col.inactive_border" = hyprRgba c.surface0 "60";
        resize_on_border = true;
        extend_border_grab_area = 30;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 8;
        active_opacity = 1.0;
        inactive_opacity = 0.95;

        shadow = {
          enabled = true;
          range = 12;
          render_power = 3;
          color = hyprRgba c.accent "33";
          color_inactive = hyprRgba c.bg-dark "00";
        };

        blur = {
          enabled = true;
          size = 5;
          passes = 3;
          noise = 0.01;
          contrast = 0.9;
          vibrancy = 0.17;
        };
      };

      # Layouts
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = {
        new_status = "master";
      };

      # Cursor — disable warping on focus/workspace changes (prevents teleporting on multi-monitor)
      cursor = {
        no_warps = true;
      };

      # Misc
      misc = {
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
      };

      # Input
      input = {
        kb_layout = "us,ru";
        kb_options = "grp:toggle";
        follow_mouse = 1;
        sensitivity = 0;

        touchpad = {
          natural_scroll = false;
        };
      };

      # Variables
      "$mainMod" = "SUPER";

      # Plugin configuration
      "plugin:hyprsplit" = {
        num_workspaces = 10;
      };
    };
  };
}
