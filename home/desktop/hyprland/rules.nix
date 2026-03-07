# Hyprland window rules and layer rules
{
  wayland.windowManager.hyprland.settings = {
    # Layer rules — blur behind translucent layers
    layerrule = [
      "blur on, match:namespace waybar"
      "ignore_alpha 0.3, match:namespace waybar"
      "blur on, match:namespace walker"
      "ignore_alpha 0.3, match:namespace walker"
      "blur on, match:namespace notifications"
      "ignore_alpha 0.3, match:namespace notifications"
      "blur on, match:namespace volume_osd"
      "ignore_alpha 0.3, match:namespace volume_osd"
    ];

    # Window rules
    windowrule = [
      "suppress_event maximize, match:class .*"
      "float on, match:class com.gabm.satty"
      "float on, match:class gsimplecal"
      "move cursor -50% 34, match:class gsimplecal"

      # Zoom — reduce rendering overhead to prevent lag
      "no_blur true, match:class zoom"
      "no_shadow true, match:class zoom"
      "no_anim true, match:class zoom"
      "immediate true, match:class zoom"

      # JetBrains IDEs / Android Studio — float popups & dialogs
      "float on, match:class jetbrains-.*, match:title (win.*|splash)"
      "center 1, match:class jetbrains-.*, match:title splash"
      "no_initial_focus on, match:class jetbrains-.*, match:title win.*"
      "no_focus on, match:class jetbrains-.*, match:title win.*"
      "suppress_event focus, match:class jetbrains-.*, match:title win.*"
    ];
  };
}
