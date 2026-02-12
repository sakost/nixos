# Hyprland user configuration
{ pkgs, ... }:

let
  overrideFile = "/tmp/hypr-workspace-overrides";

  # Custom workspace auto-namer: per-monitor display numbers + client icons
  # Respects manual renames stored in the override file
  hypr-autoname = pkgs.writeShellScriptBin "hyprland-autoname-workspaces" ''
    OVERRIDE_FILE="${overrideFile}"
    touch "$OVERRIDE_FILE"

    shopt -s nocasematch

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

    display_num() {
      echo $(( ($1 - 1) % 10 + 1 ))
    }

    rename_workspace() {
      local ws_id=$1
      [[ $ws_id -lt 1 ]] && return 0
      local dn
      dn=$(display_num "$ws_id")

      # Check for manual override
      local override=""
      override=$(${pkgs.gnugrep}/bin/grep "^''${ws_id}=" "$OVERRIDE_FILE" 2>/dev/null | tail -1 | cut -d= -f2-) || true
      if [[ -n "$override" ]]; then
        hyprctl dispatch renameworkspace "$ws_id" "$override"
        return
      fi

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
        hyprctl dispatch renameworkspace "$ws_id" "$dn $icons"
      else
        hyprctl dispatch renameworkspace "$ws_id" "$dn"
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

  # Workspace rename command (writes to override file so autoname respects it)
  hypr-rename = pkgs.writeShellScriptBin "hypr-rename-workspace" ''
    OVERRIDE_FILE="${overrideFile}"
    touch "$OVERRIDE_FILE"

    ID=$(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq -r .id)
    DN=$(( (ID - 1) % 10 + 1 ))

    NAME=$(rofi -dmenu -p "Rename workspace $DN:" -theme-str "listview {enabled: false;}") || true

    # Remove old override for this workspace
    ${pkgs.gnused}/bin/sed -i "/^''${ID}=/d" "$OVERRIDE_FILE"

    if [[ -n "$NAME" ]]; then
      echo "''${ID}=''${DN} ''${NAME}" >> "$OVERRIDE_FILE"
      hyprctl dispatch renameworkspace "$ID" "$DN $NAME"
    else
      # Clear override, let autoname handle it
      hyprctl dispatch renameworkspace "$ID" "$DN"
    fi
  '';
in
{
  home.packages = [ hypr-autoname hypr-rename ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    plugins = [
      pkgs.hyprlandPlugins.hyprsplit
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
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"
        # Nvidia specific
        "LIBVA_DRIVER_NAME,nvidia"
        "XDG_SESSION_TYPE,wayland"
        "GBM_BACKEND,nvidia-drm"
        "__GLX_VENDOR_LIBRARY_NAME,nvidia"
        "WLR_NO_HARDWARE_CURSORS,1"
        "__GL_VRR_ALLOWED,1"
      ];

      # Programs
      "$terminal" = "alacritty";
      "$fileManager" = "nautilus";
      "$menu" = "rofi -show drun";

      # Autostart (waybar is managed by home-manager systemd service)
      exec-once = [
        "swww-daemon"
        "wl-paste --watch cliphist store"
        "hyprland-autoname-workspaces"
        "telegram-desktop -startintray"
        "spotify"
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
      #   SUPER + V            — toggle floating
      #   SUPER + R            — app launcher (rofi)
      #   SUPER + P            — pseudo-tile
      #   SUPER + J            — toggle split direction
      #   SUPER + arrows       — move focus (left/right/up/down)
      #   SUPER + left-click   — drag to move window
      #   SUPER + right-click  — drag to resize window
      #
      # Workspaces:
      #   SUPER + 1-9,0        — switch to workspace 1-10 (per-monitor via hyprsplit)
      #   SUPER + SHIFT + 1-9,0 — move window to workspace 1-10 (per-monitor)
      #   SUPER + N            — rename current workspace (rofi prompt)
      #   SUPER + S            — toggle scratchpad workspace
      #   SUPER + SHIFT + S    — move window to scratchpad
      #   SUPER + mouse scroll — cycle workspaces
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
        "$mainMod, escape, exec, wlogout"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating"
        "$mainMod, R, exec, $menu"
        "$mainMod, P, pseudo"
        "$mainMod, J, togglesplit"

        # Focus movement
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Workspaces (hyprsplit — per-monitor independent workspaces)
        "$mainMod, 1, split:workspace, 1"
        "$mainMod, 2, split:workspace, 2"
        "$mainMod, 3, split:workspace, 3"
        "$mainMod, 4, split:workspace, 4"
        "$mainMod, 5, split:workspace, 5"
        "$mainMod, 6, split:workspace, 6"
        "$mainMod, 7, split:workspace, 7"
        "$mainMod, 8, split:workspace, 8"
        "$mainMod, 9, split:workspace, 9"
        "$mainMod, 0, split:workspace, 10"

        # Move to workspace
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

        # Rename workspace (writes to override file, respected by autoname daemon)
        "$mainMod, N, exec, hypr-rename-workspace"

        # Special workspace
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll workspaces
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"

        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy -t image/png"
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

      # hyprsplit: 10 independent workspaces per monitor
      plugin.hyprsplit.num_workspaces = 10;

      # Window rules
      windowrule = [
        "suppress_event maximize, match:class .*"
      ];
    };
  };
}
