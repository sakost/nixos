# Hyprland workspace scripts and their systemd services
{ pkgs, ... }:

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
}
