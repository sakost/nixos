# Hyprland user configuration
{ config, pkgs, ... }:

let
  numWorkspaces = 10;

  # Synchronized workspace switching: switches all monitors to the same workspace number
  hypr-sync-ws = pkgs.writeShellScriptBin "hypr-sync-ws" ''
    NUM_WS=${toString numWorkspaces}
    ARG=$1

    FOCUSED_MON=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

    if [[ "$ARG" == "next" || "$ARG" == "prev" ]]; then
      CURRENT_ID=$(hyprctl -j monitors | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
      LOGICAL=$(( ((CURRENT_ID - 1) % NUM_WS) + 1 ))
      if [[ "$ARG" == "next" ]]; then
        TARGET=$(( LOGICAL % NUM_WS + 1 ))
      else
        TARGET=$(( (LOGICAL - 2 + NUM_WS) % NUM_WS + 1 ))
      fi
    else
      TARGET=$ARG
    fi

    # Switch non-focused monitors first, then focused last to preserve focus
    BATCH=""
    for MON in $(hyprctl -j monitors | ${pkgs.jq}/bin/jq -r '.[].name'); do
      if [[ "$MON" != "$FOCUSED_MON" ]]; then
        BATCH+="dispatch focusmonitor $MON ; dispatch split:workspace $TARGET ; "
      fi
    done
    BATCH+="dispatch focusmonitor $FOCUSED_MON ; dispatch split:workspace $TARGET"

    hyprctl --batch "$BATCH"

    # Immediately rename active workspaces to prevent brief display of internal IDs (e.g. 11 instead of 1)
    RENAME_BATCH=""
    for WS_ID in $(hyprctl -j monitors | ${pkgs.jq}/bin/jq -r '.[].activeWorkspace.id'); do
      LOGICAL=$(( ((WS_ID - 1) % NUM_WS) + 1 ))
      RENAME_BATCH+="dispatch renameworkspace $WS_ID $LOGICAL ; "
    done
    [ -n "$RENAME_BATCH" ] && hyprctl --batch "$RENAME_BATCH"
  '';

  # Custom workspace auto-namer: adds app icons next to workspace numbers
  hypr-autoname = pkgs.writeShellScriptBin "hyprland-autoname-workspaces" ''
    shopt -s nocasematch

    NUM_WS=${toString numWorkspaces}

    get_icon() {
      case "$1" in
        alacritty) echo $'\ue795' ;;
        google-chrome) echo $'\uf268' ;;
        firefox) echo $'\uf269' ;;
        org.telegram.desktop|telegram*) echo $'\uf2c6' ;;
        spotify) echo $'\uf1bc' ;;
        nautilus) echo $'\uf413' ;;
        code|code-*) echo $'\ue70c' ;;
        neovide) echo $'\ue7c5' ;;
        discord) echo $'\uf392' ;;
        zoom) echo $'\uf03d' ;;
        obsidian) echo $'\uf5d2' ;;
        android-studio|jetbrains-*) echo $'\ue70e' ;;
        claude) echo $'\uf544' ;;
        yandex*) echo $'\uf268' ;;
        *) echo $'\uf4ae' ;;
      esac
    }

    rename_workspace() {
      local ws_id=$1
      [[ $ws_id -lt 1 ]] && return 0

      # Display logical workspace number (1-N) instead of internal ID
      local logical_num=$(( ((ws_id - 1) % NUM_WS) + 1 ))

      # Build icon string from client classes (deduplicated)
      local icons=""
      local seen=""
      while IFS= read -r class; do
        [[ -z "$class" ]] && continue
        local icon
        icon=$(get_icon "$class")
        if [[ -n "$icon" && ! " $seen " == *" $icon "* ]]; then
          icons="''${icons:+$icons }$icon"
          seen="$seen $icon"
        fi
      done < <(hyprctl clients -j | ${pkgs.jq}/bin/jq -r ".[] | select(.workspace.id == $ws_id) | .class" | sort -u)

      if [[ -n "$icons" ]]; then
        hyprctl dispatch renameworkspace "$ws_id" "$logical_num $icons"
      else
        hyprctl dispatch renameworkspace "$ws_id" "$logical_num"
      fi
    }

    rename_all() {
      local ws_ids
      ws_ids=$(hyprctl workspaces -j | ${pkgs.jq}/bin/jq -r '.[].id')
      while IFS= read -r ws_id; do
        [[ -z "$ws_id" ]] && continue
        rename_workspace "$ws_id"
      done <<< "$ws_ids"
    }

    sleep 1
    rename_all

    ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while IFS= read -r event; do
      case "$event" in
        openwindow*|closewindow*|movewindow*|workspace*)
          sleep 0.15
          rename_all
          ;;
      esac
    done
  '';

  # Daemon that keeps all monitors on the same logical workspace
  # Catches desync from Waybar clicks or any other non-synced source
  hypr-ws-sync-daemon = pkgs.writeShellScriptBin "hypr-ws-sync-daemon" ''
    NUM_WS=${toString numWorkspaces}
    LOCK="/tmp/hypr-ws-sync-$$.lock"
    trap "rm -f $LOCK" EXIT

    sync_if_needed() {
      # Cooldown: skip if we just synced (prevents loops from our own events)
      if [[ -f "$LOCK" ]]; then return; fi

      local monitors
      monitors=$(hyprctl -j monitors)

      local focused_mon focused_ws_id target
      focused_mon=$(echo "$monitors" | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')
      focused_ws_id=$(echo "$monitors" | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .activeWorkspace.id')
      target=$(( ((focused_ws_id - 1) % NUM_WS) + 1 ))

      # Check if any monitor is out of sync
      local needs_sync=false
      while IFS=: read -r mon ws_id; do
        if [[ "$mon" != "$focused_mon" ]]; then
          local logical=$(( ((ws_id - 1) % NUM_WS) + 1 ))
          if [[ "$logical" != "$target" ]]; then
            needs_sync=true
            break
          fi
        fi
      done < <(echo "$monitors" | ${pkgs.jq}/bin/jq -r '.[] | "\(.name):\(.activeWorkspace.id)"')

      if $needs_sync; then
        touch "$LOCK"

        local batch=""
        for mon in $(echo "$monitors" | ${pkgs.jq}/bin/jq -r '.[].name'); do
          if [[ "$mon" != "$focused_mon" ]]; then
            batch+="dispatch focusmonitor $mon ; dispatch split:workspace $target ; "
          fi
        done
        batch+="dispatch focusmonitor $focused_mon"
        hyprctl --batch "$batch"

        # Cooldown to absorb events from our own sync
        (sleep 0.5; rm -f "$LOCK") &
      fi
    }

    sleep 2
    ${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while IFS= read -r event; do
      case "$event" in
        workspace*)
          sleep 0.1
          sync_if_needed
          ;;
      esac
    done
  '';
in
{
  home.packages = [ hypr-autoname hypr-sync-ws hypr-ws-sync-daemon ];

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
        # GTK4 4.20+ renamed ngl→gl; needed for walker and other GTK4 apps on Nvidia
        "GSK_RENDERER,gl"
        # Java/Swing apps (Android Studio, JetBrains IDEs)
        "_JAVA_AWT_WM_NONREPARENTING,1"
      ];

      # Programs
      "$terminal" = "uwsm app -- alacritty";
      "$fileManager" = "uwsm app -- nautilus";
      "$menu" = "walker";

      # Autostart (waybar is managed by home-manager systemd service)
      # GUI apps use "uwsm app --" to get proper systemd scope isolation
      # (prevents NOTIFY_SOCKET hijacking that can crash Hyprland)
      exec-once = [
        "uwsm app -- eww open dashboard"
        "uwsm app -- spotify"
      ];

      # General
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      # Decoration
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;

        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      # Animations
      animations = {
        enabled = true;

        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1"
          "quick, 0.15, 0, 0.1, 1"
        ];

        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "workspaces, 1, 1.94, almostLinear, fade"
        ];
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
        force_default_wallpaper = -1;
        disable_hyprland_logo = false;
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

      # ── Keybindings ──────────────────────────────────────────────
      #
      # Windows:
      #   SUPER + Q            — open terminal
      #   SUPER + C            — close window
      #   SUPER + Escape       — power menu (wlogout)
      #   SUPER + E            — file manager
      #   SUPER + V            — clipboard history (walker)
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
      # Overview:
      #   SUPER + TAB          — window switcher (walker)
      #
      # Session:
      #   SUPER + D            — lock screen (hyprlock)
      #   SUPER + Escape       — power menu (wlogout)
      #
      # Media / misc:
      #   Print                — screenshot (region → clipboard)
      #   Right Alt            — switch keyboard layout (via XKB)
      #   Volume/media keys    — audio & player control
      # ─────────────────────────────────────────────────────────────

      bind = [
        # Apps
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive"
        "$mainMod, D, exec, hyprlock"
        "$mainMod, escape, exec, uwsm app -- wlogout"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, F, togglefloating"
        "$mainMod, space, exec, $menu"
        "$mainMod, P, pseudo"
        "$mainMod, J, togglesplit"

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
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy -t image/png"
        "SHIFT, Print, exec, grim -g \"$(slurp)\" - | satty -f -"
        "$mainMod, Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
      ];

      # Mouse bindings
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Media keys
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      bindl = [
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPause, exec, playerctl play-pause"
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioPrev, exec, playerctl previous"
      ];

      # Plugin configuration
      "plugin:hyprsplit" = {
        num_workspaces = numWorkspaces;
      };

      # Hyprspace overview (disabled — plugin broken with Hyprland 0.53.3)
      # "plugin:overview" = {
      #   autoDrag = true;
      #   exitOnClick = true;
      #   showNewWorkspace = true;
      # };

      # Window rules
      windowrule = [
        "suppress_event maximize, match:class .*"
        "float on, match:class com.gabm.satty"
        # JetBrains IDEs / Android Studio — float popups & dialogs
        "float on, match:class jetbrains-.*, match:title (win.*|splash)"
        "center 1, match:class jetbrains-.*, match:title splash"
        "no_initial_focus on, match:class jetbrains-.*, match:title win.*"
        "no_focus on, match:class jetbrains-.*, match:title win.*"
        "suppress_event focus, match:class jetbrains-.*, match:title win.*"
      ];
    };
  };

  systemd.user.services.hyprland-autoname-workspaces = {
    Unit = {
      Description = "Hyprland workspace auto-namer";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${hypr-autoname}/bin/hyprland-autoname-workspaces";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.hypr-ws-sync-daemon = {
    Unit = {
      Description = "Hyprland workspace sync daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${hypr-ws-sync-daemon}/bin/hypr-ws-sync-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.telegram-desktop = {
    Unit = {
      Description = "Telegram Desktop";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.telegram-desktop}/bin/Telegram -startintray";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
