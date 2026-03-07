# Hyprland animations — bezier curves and animation rules
{
  wayland.windowManager.hyprland.settings = {
    animations = {
      enabled = true;

      bezier = [
        "snappy, 0.05, 0.9, 0.1, 1.05"
        "smooth, 0.25, 0.1, 0.25, 1"
        "linear, 0, 0, 1, 1"
      ];

      animation = [
        # Windows pop in instead of sliding
        "windows, 1, 4, snappy, popin 80%"
        "windowsOut, 1, 4, snappy, popin 80%"

        # Layers (waybar, walker, OSD) — fade in/out
        "layers, 1, 3, smooth, fade"
        "layersIn, 1, 3, smooth, fade"
        "layersOut, 1, 3, smooth, fade"

        "fade, 1, 3, smooth"

        # Workspaces slide horizontally
        "workspaces, 1, 4, smooth, slide"

        # Special workspaces fade to avoid vertical slide
        "specialWorkspaceIn, 1, 4, smooth, fade"
        "specialWorkspaceOut, 1, 4, smooth, fade"
      ];
    };
  };
}
