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

    rename_all() {
      # Fetch clients and workspaces in minimal calls
      local clients workspaces
      clients=$(hyprctl clients -j)
      workspaces=$(hyprctl workspaces -j)
      local batch=""
      while IFS=$'\t' read -r ws_id ws_name; do
        [[ -z "$ws_id" ]] && continue
        [[ $ws_id -lt 1 ]] && continue

        local logical_num=$(( ((ws_id - 1) % NUM_WS) + 1 ))
        local icons=""
        local seen=""
        while IFS= read -r class; do
          [[ -z "$class" ]] && continue
          local icon
          icon=$(get_icon "$class")
          if [[ -n "$icon" && " $seen " != *" $icon "* ]]; then
            icons="''${icons:+$icons }$icon"
            seen="$seen $icon"
          fi
        done < <(echo "$clients" | ${pkgs.jq}/bin/jq -r ".[] | select(.workspace.id == $ws_id) | .class" | sort -u)

        local new_name
        if [[ -n "$icons" ]]; then
          new_name="$logical_num $icons"
        else
          new_name="$logical_num"
        fi

        # Only rename if the name actually changed (compare to current from hyprctl)
        if [[ "$ws_name" != "$new_name" ]]; then
          batch+="dispatch renameworkspace $ws_id $new_name ; "
        fi
      done < <(echo "$workspaces" | ${pkgs.jq}/bin/jq -r '.[] | "\(.id)\t\(.name)"')
      [ -n "$batch" ] && hyprctl --batch "$batch"
    }

    sleep 1
    rename_all

    DEBOUNCE_LOCK="/tmp/hypr-autoname-debounce.$$"
    trap "rm -f $DEBOUNCE_LOCK" EXIT

    while IFS= read -r event; do
      case "$event" in
        openwindow*|closewindow*|movewindow*|workspace*)
          # Debounce: mark pending, skip if already waiting
          if [[ ! -f "$DEBOUNCE_LOCK" ]]; then
            touch "$DEBOUNCE_LOCK"
            ( sleep 0.15; rename_all; rm -f "$DEBOUNCE_LOCK" ) &
          fi
          ;;
      esac
    done < <(${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" -)
  '';

  # Interactive monitor resolution/refresh-rate picker
  # Preserves current position, scale, and extra flags (HDR, bitdepth, etc.)
  hypr-monitor-mgr = pkgs.writeShellScriptBin "hypr-monitor-mgr" ''
    JQ="${pkgs.jq}/bin/jq"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"

    MON_JSON=$(hyprctl monitors -j)

    # Get monitors
    MONITORS=$(echo "$MON_JSON" | $JQ -r '.[].name')
    MON_COUNT=$(echo "$MONITORS" | wc -l)

    if [ "$MON_COUNT" -gt 1 ]; then
      MONITOR=$(echo "$MONITORS" | walker -d)
    else
      MONITOR=$(echo "$MONITORS" | head -1)
    fi

    [ -z "$MONITOR" ] && exit 0

    # Get current settings to preserve them
    CUR_SCALE=$(echo "$MON_JSON" | $JQ -r ".[] | select(.name == \"$MONITOR\") | .scale")
    CUR_X=$(echo "$MON_JSON" | $JQ -r ".[] | select(.name == \"$MONITOR\") | .x")
    CUR_Y=$(echo "$MON_JSON" | $JQ -r ".[] | select(.name == \"$MONITOR\") | .y")

    # Resolution
    RESOLUTIONS="3840x2160
2560x1440
1920x1080
1600x900
1366x768
1280x720"

    RES=$(echo "$RESOLUTIONS" | walker -d)
    [ -z "$RES" ] && exit 0

    # Refresh rate
    RATES="240Hz
165Hz
144Hz
120Hz
100Hz
75Hz
60Hz
30Hz"

    RATE_LABEL=$(echo "$RATES" | walker -d)
    [ -z "$RATE_LABEL" ] && exit 0

    RATE=''${RATE_LABEL%Hz}

    CMD="$MONITOR,''${RES}@''${RATE},''${CUR_X}x''${CUR_Y},''${CUR_SCALE}"
    $NOTIFY "Display Update" "Applying: $RES @ ''${RATE}Hz on $MONITOR (scale ''${CUR_SCALE})"
    hyprctl keyword monitor "$CMD"
  '';

  # Wallpaper picker — browse ~/Pictures/wallpapers with walker dmenu
  hypr-wallpaper = pkgs.writeShellScriptBin "hypr-wallpaper" ''
    WALLPAPER_DIR="$HOME/Pictures/wallpapers"
    WE_DIR="$HOME/games/SteamLibrary/steamapps/workshop/content/431960"
    WE_ASSETS="$HOME/games/SteamLibrary/steamapps/common/wallpaper_engine/assets"
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    SWWW="${pkgs.awww}/bin/awww"
    MPVPAPER="${pkgs.mpvpaper}/bin/mpvpaper"
    WE="${pkgs.linux-wallpaperengine}/bin/linux-wallpaperengine"
    JQ="${pkgs.jq}/bin/jq"

    [ ! -d "$WALLPAPER_DIR" ] && mkdir -p "$WALLPAPER_DIR"

    # Build picker list: regular files + Wallpaper Engine scenes
    ENTRIES=""

    # Regular wallpaper files
    FILES=$(find "$WALLPAPER_DIR" -maxdepth 2 -type f \( \
      -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' -o -name '*.gif' \
      -o -name '*.mp4' -o -name '*.webm' -o -name '*.mkv' \
    \) 2>/dev/null | sort)
    if [ -n "$FILES" ]; then
      ENTRIES=$(echo "$FILES" | sed "s|$WALLPAPER_DIR/||")
    fi

    # Wallpaper Engine scenes
    if [ -d "$WE_DIR" ]; then
      for dir in "$WE_DIR"/*/; do
        [ ! -d "$dir" ] && continue
        id=$(basename "$dir")
        title=$($JQ -r '.title // empty' "$dir/project.json" 2>/dev/null)
        [ -z "$title" ] && title="WE #$id"
        ENTRIES=$(printf '%s\n[WE] %s' "$ENTRIES" "$title")
      done
    fi

    ENTRIES=$(echo "$ENTRIES" | sed '/^$/d')

    if [ -z "$ENTRIES" ]; then
      $NOTIFY "Wallpaper Picker" "No wallpapers found"
      exit 0
    fi

    SELECTION=$(echo "$ENTRIES" | walker -d)
    [ -z "$SELECTION" ] && exit 0

    # Get monitors
    MONITORS=$(hyprctl monitors -j | $JQ -r '.[].name')
    MON_COUNT=$(echo "$MONITORS" | wc -l)

    if [ "$MON_COUNT" -gt 1 ]; then
      TARGET=$(printf 'All monitors\n%s' "$MONITORS" | walker -d)
      [ -z "$TARGET" ] && exit 0
    else
      TARGET=$(echo "$MONITORS" | head -1)
    fi

    # Kill conflicting wallpaper backends before applying
    kill_we() { pkill -f linux-wallpaperengine 2>/dev/null; sleep 0.3; }
    kill_mpv() { pkill -f mpvpaper 2>/dev/null; sleep 0.3; }

    if [[ "$SELECTION" == "[WE] "* ]]; then
      # Wallpaper Engine scene
      WE_TITLE="''${SELECTION#\[WE\] }"
      WE_ID=""
      for dir in "$WE_DIR"/*/; do
        title=$($JQ -r '.title // empty' "$dir/project.json" 2>/dev/null)
        if [ "$title" = "$WE_TITLE" ]; then
          WE_ID=$(basename "$dir")
          break
        fi
      done
      [ -z "$WE_ID" ] && { $NOTIFY "Wallpaper" "Could not find WE scene"; exit 1; }

      kill_we
      kill_mpv

      apply_we() {
        $WE --assets-dir "$WE_ASSETS" --fps=60 --silent --screen-root="$1" --bg "$WE_DIR/$WE_ID" &
        disown
      }

      if [ "$TARGET" = "All monitors" ]; then
        while IFS= read -r MON; do
          apply_we "$MON"
        done <<< "$MONITORS"
        $NOTIFY "Wallpaper" "WE: $WE_TITLE → all monitors"
      else
        apply_we "$TARGET"
        $NOTIFY "Wallpaper" "WE: $WE_TITLE → $TARGET"
      fi

    elif [[ "$SELECTION" == *.mp4 || "$SELECTION" == *.webm || "$SELECTION" == *.mkv ]]; then
      # Video wallpaper
      FULL_PATH="$WALLPAPER_DIR/$SELECTION"
      [ ! -f "$FULL_PATH" ] && exit 1
      kill_mpv
      kill_we

      apply_video() {
        $MPVPAPER -o "no-audio loop" "$1" "$FULL_PATH" &
        disown
      }

      if [ "$TARGET" = "All monitors" ]; then
        while IFS= read -r MON; do
          apply_video "$MON"
        done <<< "$MONITORS"
        $NOTIFY "Wallpaper" "Video applied to all monitors"
      else
        apply_video "$TARGET"
        $NOTIFY "Wallpaper" "Video applied to $TARGET"
      fi

    else
      # Static images and GIFs — use swww
      FULL_PATH="$WALLPAPER_DIR/$SELECTION"
      [ ! -f "$FULL_PATH" ] && exit 1
      kill_we
      kill_mpv

      if [ "$TARGET" = "All monitors" ]; then
        $SWWW img "$FULL_PATH" --transition-type grow --transition-duration 1.5
        $NOTIFY "Wallpaper" "Applied to all monitors"
      else
        $SWWW img -o "$TARGET" "$FULL_PATH" --transition-type grow --transition-duration 1.5
        $NOTIFY "Wallpaper" "Applied to $TARGET"
      fi
    fi
  '';

  # Bluetooth manager — toggle power, scan, connect/disconnect via walker dmenu
  hypr-bluetooth = pkgs.writeShellScriptBin "hypr-bluetooth" ''
    NOTIFY="${pkgs.libnotify}/bin/notify-send"
    BT="${pkgs.bluez}/bin/bluetoothctl"

    # Check if bluetooth is powered on
    POWERED=$($BT show | grep -q "Powered: yes" && echo "yes" || echo "no")

    if [ "$POWERED" = "no" ]; then
      ACTION=$(printf 'Power On\nExit' | walker -d)
      case "$ACTION" in
        "Power On")
          $BT power on
          $NOTIFY "Bluetooth" "Powered on"
          sleep 1
          ;;
        *) exit 0 ;;
      esac
    fi

    # Get paired devices
    PAIRED=$($BT devices Paired 2>/dev/null || $BT paired-devices 2>/dev/null)

    # Build menu
    MENU="Scan for devices"
    if [ -n "$PAIRED" ]; then
      DEVICES=$(echo "$PAIRED" | sed 's/^Device //' | while read -r mac name; do
        CONNECTED=$($BT info "$mac" 2>/dev/null | grep -q "Connected: yes" && echo "[connected]" || echo "")
        echo "$name $CONNECTED ($mac)"
      done)
      MENU=$(printf '%s\n%s\nPower Off' "$DEVICES" "$MENU")
    else
      MENU=$(printf '%s\nPower Off' "$MENU")
    fi

    CHOICE=$(echo "$MENU" | walker -d)
    [ -z "$CHOICE" ] && exit 0

    case "$CHOICE" in
      "Scan for devices")
        $NOTIFY "Bluetooth" "Scanning for 10 seconds..."
        $BT --timeout 10 scan on &
        sleep 10
        FOUND=$($BT devices | sed 's/^Device //' | while read -r mac name; do
          echo "$name ($mac)"
        done)
        if [ -z "$FOUND" ]; then
          $NOTIFY "Bluetooth" "No devices found"
          exit 0
        fi
        DEV=$(echo "$FOUND" | walker -d)
        [ -z "$DEV" ] && exit 0
        MAC=$(echo "$DEV" | grep -oiP '\(([0-9A-Fa-f:]+)\)' | tr -d '()')
        [ -z "$MAC" ] && exit 0
        $BT pair "$MAC" 2>/dev/null
        $BT connect "$MAC"
        $NOTIFY "Bluetooth" "Connected to $DEV"
        ;;
      "Power Off")
        $BT power off
        $NOTIFY "Bluetooth" "Powered off"
        ;;
      *)
        # Toggle connection on selected device
        MAC=$(echo "$CHOICE" | grep -oiP '\(([0-9A-Fa-f:]+)\)' | tr -d '()')
        [ -z "$MAC" ] && exit 0
        if echo "$CHOICE" | grep -q "\[connected\]"; then
          $BT disconnect "$MAC"
          $NOTIFY "Bluetooth" "Disconnected"
        else
          $BT connect "$MAC"
          $NOTIFY "Bluetooth" "Connected"
        fi
        ;;
    esac
  '';

  # Open cheatsheet markdown files in a floating terminal
  hypr-cheatsheet = pkgs.writeShellScriptBin "hypr-cheatsheet" ''
    DOCS_DIR="$HOME/nixos-config/docs"
    [ ! -d "$DOCS_DIR" ] && exit 1

    FILES=$(find "$DOCS_DIR" -name '*.md' -type f | sort)
    [ -z "$FILES" ] && exit 0

    CHOICE=$(echo "$FILES" | sed "s|$DOCS_DIR/||" | walker -d)
    [ -z "$CHOICE" ] && exit 0

    FULL_PATH="$DOCS_DIR/$CHOICE"
    [ ! -f "$FULL_PATH" ] && exit 1

    alacritty --class floating-cheatsheet -e ${pkgs.mdcat}/bin/mdcat -p "$FULL_PATH"
  '';

  # Daemon that keeps all monitors on the same logical workspace
  # Catches desync from Waybar clicks or any other non-synced source
  hypr-ws-sync-daemon = pkgs.writeShellScriptBin "hypr-ws-sync-daemon" ''
    NUM_WS=${toString numWorkspaces}
    LOCK="/tmp/hypr-ws-sync-$$.lock"

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

    DEBOUNCE_LOCK="/tmp/hypr-ws-sync-debounce.$$"
    trap "rm -f $LOCK $DEBOUNCE_LOCK" EXIT

    sleep 2
    while IFS= read -r event; do
      case "$event" in
        workspace*)
          if [[ ! -f "$DEBOUNCE_LOCK" ]]; then
            touch "$DEBOUNCE_LOCK"
            ( sleep 0.3; sync_if_needed; rm -f "$DEBOUNCE_LOCK" ) &
          fi
          ;;
      esac
    done < <(${pkgs.socat}/bin/socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" -)
  '';
  # USB device notification popup — monitors udev events and shows eww popup
  usb-notify = pkgs.writeShellScriptBin "usb-notify" ''
    EWW="${pkgs.eww}/bin/eww"
    AWK="${pkgs.gawk}/bin/awk"
    NUMFMT="${pkgs.coreutils}/bin/numfmt"
    LSBLK="${pkgs.util-linux}/bin/lsblk"

    DEBOUNCE_DIR="/tmp/usb-notify-debounce"
    mkdir -p "$DEBOUNCE_DIR"
    CLOSE_PID_FILE="/tmp/usb-popup-pid"

    # Icons (Nerd Font via printf to survive Nix interpolation)
    ICON_STORAGE=$(printf '\U000f0449')
    ICON_KEYBOARD=$(printf '\U000f030c')
    ICON_MOUSE=$(printf '\U000f037d')
    ICON_AUDIO=$(printf '\U000f036c')
    ICON_CAMERA=$(printf '\U000f0100')
    ICON_USB=$(printf '\U000f0618')

    # Collect already-connected devices at startup
    declare -A KNOWN_USB_DEVICES
    for dev in /sys/bus/usb/devices/*/idVendor; do
      [ -f "$dev" ] || continue
      devdir="$(dirname "$dev")"
      devname="$(basename "$devdir")"
      KNOWN_USB_DEVICES["$devname"]=1
    done

    declare -A KNOWN_BLOCK_DEVICES
    for dev in /sys/class/block/*/device; do
      [ -d "$dev" ] || continue
      devdir="$(dirname "$dev")"
      devname="$(basename "$devdir")"
      KNOWN_BLOCK_DEVICES["$devname"]=1
    done

    detect_type() {
      local syspath="$1"
      local devtype=""

      # Check bInterfaceClass for USB interface type
      for iface in "$syspath"/*/bInterfaceClass "$syspath"/bInterfaceClass; do
        [ -f "$iface" ] || continue
        local class
        class=$(cat "$iface" 2>/dev/null)
        case "$class" in
          08) devtype="storage"; break ;;
          03)
            # HID — check bInterfaceProtocol: 1=keyboard, 2=mouse
            local proto_file
            proto_file="$(dirname "$iface")/bInterfaceProtocol"
            local proto
            proto=$(cat "$proto_file" 2>/dev/null)
            case "$proto" in
              01) devtype="keyboard"; break ;;
              02) devtype="mouse"; break ;;
              *)  devtype="hid"; break ;;
            esac
            ;;
          01) devtype="audio"; break ;;
          0e) devtype="camera"; break ;;
        esac
      done

      echo "''${devtype:-generic}"
    }

    get_icon() {
      case "$1" in
        storage)  echo "$ICON_STORAGE" ;;
        keyboard) echo "$ICON_KEYBOARD" ;;
        mouse)    echo "$ICON_MOUSE" ;;
        audio)    echo "$ICON_AUDIO" ;;
        camera)   echo "$ICON_CAMERA" ;;
        *)        echo "$ICON_USB" ;;
      esac
    }

    get_device_info() {
      local syspath="$1"
      local vendor="" model=""

      if [ -f "$syspath/manufacturer" ]; then
        vendor=$(cat "$syspath/manufacturer" 2>/dev/null)
      elif [ -f "$syspath/idVendor" ]; then
        vendor=$(cat "$syspath/idVendor" 2>/dev/null)
      fi

      if [ -f "$syspath/product" ]; then
        model=$(cat "$syspath/product" 2>/dev/null)
      elif [ -f "$syspath/idProduct" ]; then
        model=$(cat "$syspath/idProduct" 2>/dev/null)
      fi

      echo "$vendor" "$model"
    }

    get_storage_size() {
      # Find block devices associated with this USB device
      local syspath="$1"
      local devname
      for blk in "$syspath"/host*/target*/*/block/*; do
        [ -d "$blk" ] || continue
        devname=$(basename "$blk")
        local size
        size=$($LSBLK -bno SIZE "/dev/$devname" 2>/dev/null | head -1)
        if [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null; then
          $NUMFMT --to=iec-i --suffix=B "$size"
          return
        fi
      done
      echo ""
    }

    show_popup() {
      local icon="$1" title="$2" desc="$3"

      $EWW update usb_icon="$icon" usb_title="$title" usb_desc="$desc"
      $EWW open usb_popup 2>/dev/null

      # Kill previous auto-close timer
      [ -f "$CLOSE_PID_FILE" ] && kill "$(cat "$CLOSE_PID_FILE")" 2>/dev/null
      ( sleep 5; $EWW close usb_popup 2>/dev/null ) &
      echo $! > "$CLOSE_PID_FILE"
    }

    debounce_check() {
      local key="$1"
      local stamp_file="$DEBOUNCE_DIR/$key"
      local now
      now=$(date +%s)

      if [ -f "$stamp_file" ]; then
        local prev
        prev=$(cat "$stamp_file")
        if [ $((now - prev)) -lt 3 ]; then
          return 1  # debounced
        fi
      fi
      echo "$now" > "$stamp_file"
      return 0
    }

    handle_event() {
      local action="$1" syspath="$2" subsystem="$3"

      # Extract a stable device key from the syspath
      local devkey
      devkey=$(basename "$syspath")

      if ! debounce_check "$devkey"; then
        return
      fi

      if [ "$action" = "add" ]; then
        local devtype
        devtype=$(detect_type "$syspath")
        local icon
        icon=$(get_icon "$devtype")

        local vendor="" model=""
        read -r vendor model <<< "$(get_device_info "$syspath")"

        local desc=""
        if [ -n "$vendor" ] && [ -n "$model" ]; then
          desc="$vendor $model"
        elif [ -n "$vendor" ]; then
          desc="$vendor"
        elif [ -n "$model" ]; then
          desc="$model"
        else
          desc="Unknown device"
        fi

        # For storage devices, try to get size
        if [ "$devtype" = "storage" ]; then
          # Wait briefly for block device to appear
          sleep 1
          local size
          size=$(get_storage_size "$syspath")
          [ -n "$size" ] && desc="$desc ($size)"
        fi

        local title="Device Connected"
        case "$devtype" in
          storage)  title="Storage Connected" ;;
          keyboard) title="Keyboard Connected" ;;
          mouse)    title="Mouse Connected" ;;
          audio)    title="Audio Device Connected" ;;
          camera)   title="Camera Connected" ;;
        esac

        show_popup "$icon" "$title" "$desc"

      elif [ "$action" = "remove" ]; then
        local icon="$ICON_USB"
        show_popup "$icon" "Device Disconnected" "A USB device was removed"
      fi
    }

    # Monitor udev events
    ${pkgs.systemd}/bin/udevadm monitor --udev --subsystem-match=usb --subsystem-match=block \
      | while IFS= read -r line; do
        # Lines look like: UDEV  [timestamp] add  /devices/pci.../usb1/... (usb)
        if echo "$line" | grep -qE '^UDEV'; then
          action=$(echo "$line" | $AWK '{print $3}')
          devpath=$(echo "$line" | $AWK '{print $4}')
          subsys=$(echo "$line" | $AWK -F '[()]' '{print $2}')

          if [ "$action" = "add" ] || [ "$action" = "remove" ]; then
            # Only handle top-level USB devices, not interfaces
            if [ "$subsys" = "usb" ] && [ -f "/sys$devpath/idVendor" ]; then
              handle_event "$action" "/sys$devpath" "$subsys" &
            fi
          fi
        fi
      done
  '';

in
{
  home.packages = [ hypr-autoname hypr-sync-ws hypr-ws-sync-daemon hypr-monitor-mgr usb-notify hypr-wallpaper hypr-bluetooth hypr-cheatsheet ];

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

  systemd.user.services.usb-notify = {
    Unit = {
      Description = "USB device notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${usb-notify}/bin/usb-notify";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
