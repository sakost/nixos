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
      "blur on, match:namespace brightness_osd"
      "ignore_alpha 0.3, match:namespace brightness_osd"
      "no_anim on, match:namespace usb_popup"
      "no_anim on, match:namespace bluetooth_popup"
    ];

    # Window rules
    windowrule = [
      "suppress_event maximize, match:class .*"

      # ── Utilities ──
      "float on, match:class com.gabm.satty"
      "float on, match:class gsimplecal"
      "move cursor -50% 34, match:class gsimplecal"

      # ── Chromium-based browser notifications (open as separate tiled windows) ──
      # These have empty title or title like the site name, but window type is "notification"
      # Use initialTitle empty match and specific browser classes
      "float on, match:initialTitle ^$, match:class ^(google-chrome|chromium|yandex-browser|brave-browser|microsoft-edge).*"
      "no_focus on, match:initialTitle ^$, match:class ^(google-chrome|chromium|yandex-browser|brave-browser|microsoft-edge).*"
      "pin on, match:initialTitle ^$, match:class ^(google-chrome|chromium|yandex-browser|brave-browser|microsoft-edge).*"
      "move 100%-420 48, match:initialTitle ^$, match:class ^(google-chrome|chromium|yandex-browser|brave-browser|microsoft-edge).*"
      "size 400 120, match:initialTitle ^$, match:class ^(google-chrome|chromium|yandex-browser|brave-browser|microsoft-edge).*"

      # ── Common floating dialogs ──
      "float on, match:class pavucontrol"
      "size 800 500, match:class pavucontrol"
      "center 1, match:class pavucontrol"
      "float on, match:class nm-connection-editor"
      "float on, match:class blueman-manager"
      "float on, match:class .blueman-manager-wrapped"
      "float on, match:title (Open File|Save File|Save As|Choose Files)"
      "center 1, match:title (Open File|Save File|Save As|Choose Files)"

      # ── Games — immediate rendering (no compositor latency) ──
      "immediate true, match:class ^(cs2)$"
      "immediate true, match:class ^(steam_app_.*)$"
      "fullscreen on, match:class ^(cs2)$"

      # ── Zoom — reduce rendering overhead to prevent lag ──
      "no_blur true, match:class zoom"
      "no_shadow true, match:class zoom"
      "no_anim true, match:class zoom"
      "immediate true, match:class zoom"

      # ── Cava music visualizer ──
      "float on, match:class ^(music_vis)$"
      "pin on, match:class ^(music_vis)$"
      "no_initial_focus on, match:class ^(music_vis)$"
      "size 700 350, match:class ^(music_vis)$"
      "move 12 720, match:class ^(music_vis)$"
      "no_border on, match:class ^(music_vis)$"
      "no_shadow on, match:class ^(music_vis)$"
      "opacity 0.8, match:class ^(music_vis)$"

      # ── Picture-in-picture ──
      "float on, match:title ^(Picture-in-Picture)$"
      "pin on, match:title ^(Picture-in-Picture)$"
      "size 480 270, match:title ^(Picture-in-Picture)$"
      "move 100%-490 100%-280, match:title ^(Picture-in-Picture)$"

      # ── JetBrains IDEs / Android Studio — float popups & dialogs ──
      "float on, match:class jetbrains-.*, match:title (win.*|splash)"
      "center 1, match:class jetbrains-.*, match:title splash"
      "no_initial_focus on, match:class jetbrains-.*, match:title win.*"
      "no_focus on, match:class jetbrains-.*, match:title win.*"
      "suppress_event focus, match:class jetbrains-.*, match:title win.*"

      # ── XDG desktop portal (file picker) ──
      "float on, match:class xdg-desktop-portal-gtk"
      "center 1, match:class xdg-desktop-portal-gtk"
      "size 900 600, match:class xdg-desktop-portal-gtk"
    ];
  };
}
