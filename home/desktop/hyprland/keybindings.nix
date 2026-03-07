# Hyprland keybindings
{
  wayland.windowManager.hyprland.settings = {
    # ── Keybindings ──────────────────────────────────────────────
    #
    # Windows:
    #   SUPER + Q            — open terminal
    #   SUPER + C            — close window
    #   SUPER + SHIFT + C    — force-kill (click to pick window)
    #   SUPER + CTRL + C     — hide window to hidden workspace
    #   SUPER + CTRL + V     — toggle hidden workspace
    #   SUPER + Escape       — power menu (wlogout)
    #   SUPER + E            — file manager
    #   SUPER + F            — toggle floating
    #   SUPER + Space        — app launcher (walker)
    #   SUPER + P            — pseudo-tile
    #   SUPER + J            — toggle split direction
    #   SUPER + arrows       — move focus (left/right/up/down)
    #   SUPER + left-click   — drag to move window
    #   SUPER + right-click  — drag to resize window
    #
    # Workspaces (synced across all monitors via hyprsplit):
    #   SUPER + 1-9,0        — switch all monitors to workspace 1-10
    #   SUPER + SHIFT + 1-9,0 — move window to workspace 1-10 (focused monitor)
    #   SUPER + CTRL + Right — next workspace (synced)
    #   SUPER + CTRL + Left  — previous workspace (synced)
    #   SUPER + S            — toggle scratchpad workspace
    #   SUPER + SHIFT + S    — move window to scratchpad
    #   SUPER + mouse scroll — cycle workspaces (focused monitor only)
    #
    # Walker:
    #   SUPER + Space        — app launcher
    #   SUPER + TAB          — window switcher
    #   SUPER + V            — clipboard history
    #   SUPER + T            — file browser
    #
    # Session:
    #   SUPER + D            — lock screen (hyprlock)
    #   SUPER + Escape       — power menu (wlogout)
    #   SUPER + M            — monitor management (resolution/refresh)
    #   SUPER + W            — wallpaper picker
    #   SUPER + B            — bluetooth manager
    #
    # Notifications:
    #   SUPER + N            — toggle DND mode
    #   SUPER + SHIFT + N    — toggle work mode
    #
    # Media:
    #   Volume keys          — volume OSD (eww)
    #   Brightness keys      — brightness OSD (eww)
    #   Media play/next/prev — playerctl
    #
    # Screenshots:
    #   Print                — region to clipboard
    #   SHIFT + Print        — region to satty (annotate)
    #   SUPER + Print        — region to file
    # ─────────────────────────────────────────────────────────────

    bind = [
      # Apps
      "$mainMod, Q, exec, $terminal"
      "$mainMod, C, killactive"
      "$mainMod CTRL, C, movetoworkspacesilent, special:hidden"
      "$mainMod CTRL, V, togglespecialworkspace, hidden"
      "$mainMod SHIFT, C, exec, hyprctl kill"
      "$mainMod, D, exec, hyprlock"
      "$mainMod, escape, exec, uwsm app -- wlogout"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, F, togglefloating"
      "$mainMod, space, exec, $menu"
      "$mainMod, P, pseudo"
      "$mainMod, J, togglesplit"
      "$mainMod, M, exec, hypr-monitor-mgr"
      "$mainMod, W, exec, hypr-wallpaper"
      "$mainMod, B, exec, hypr-bluetooth"

      # Focus movement
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"

      # Workspaces — synced across all monitors
      "$mainMod, 1, exec, hypr-sync-ws 1"
      "$mainMod, 2, exec, hypr-sync-ws 2"
      "$mainMod, 3, exec, hypr-sync-ws 3"
      "$mainMod, 4, exec, hypr-sync-ws 4"
      "$mainMod, 5, exec, hypr-sync-ws 5"
      "$mainMod, 6, exec, hypr-sync-ws 6"
      "$mainMod, 7, exec, hypr-sync-ws 7"
      "$mainMod, 8, exec, hypr-sync-ws 8"
      "$mainMod, 9, exec, hypr-sync-ws 9"
      "$mainMod, 0, exec, hypr-sync-ws 10"

      # Move window to workspace (focused monitor only)
      "$mainMod SHIFT, 1, split:movetoworkspace, 1"
      "$mainMod SHIFT, 2, split:movetoworkspace, 2"
      "$mainMod SHIFT, 3, split:movetoworkspace, 3"
      "$mainMod SHIFT, 4, split:movetoworkspace, 4"
      "$mainMod SHIFT, 5, split:movetoworkspace, 5"
      "$mainMod SHIFT, 6, split:movetoworkspace, 6"
      "$mainMod SHIFT, 7, split:movetoworkspace, 7"
      "$mainMod SHIFT, 8, split:movetoworkspace, 8"
      "$mainMod SHIFT, 9, split:movetoworkspace, 9"
      "$mainMod SHIFT, 0, split:movetoworkspace, 10"

      # Cycle workspaces synced across all monitors
      "$mainMod CTRL, right, exec, hypr-sync-ws next"
      "$mainMod CTRL, left, exec, hypr-sync-ws prev"

      # Hyprspace overview (disabled — plugin broken with Hyprland 0.53.3)
      # "$mainMod, TAB, overview:toggle"

      # Special workspace (scratchpad — not synced)
      "$mainMod, S, togglespecialworkspace, magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"

      # Scroll workspaces (synced across all monitors)
      "$mainMod, mouse_down, exec, hypr-sync-ws next"
      "$mainMod, mouse_up, exec, hypr-sync-ws prev"

      # Notification profiles (mako modes)
      "$mainMod, N, exec, makoctl mode | grep -q dnd && makoctl mode -r dnd || makoctl mode -a dnd"
      "$mainMod SHIFT, N, exec, makoctl mode | grep -q work && makoctl mode -r work || makoctl mode -a work"

      # Walker providers
      "$mainMod, T, exec, walker -m files"
      "$mainMod, TAB, exec, walker -m windows"
      "$mainMod, V, exec, walker -m clipboard"

      # Screenshot
      '', Print, exec, grim -g "$(slurp)" - | wl-copy -t image/png''
      ''SHIFT, Print, exec, grim -g "$(slurp)" - | satty -f -''
      ''$mainMod, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png''
    ];

    # Mouse bindings
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];

    # Media keys (with volume/brightness OSD)
    bindel = [
      ", XF86AudioRaiseVolume, exec, eww-volume-osd raise"
      ", XF86AudioLowerVolume, exec, eww-volume-osd lower"
      ", XF86AudioMute, exec, eww-volume-osd mute"
      ", XF86AudioMicMute, exec, eww-volume-osd mic-mute"
      ", XF86MonBrightnessUp, exec, eww-brightness-osd raise"
      ", XF86MonBrightnessDown, exec, eww-brightness-osd lower"
    ];

    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };
}
