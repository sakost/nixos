# Eww glassmorphic dashboard overlay for HDMI-A-1
# Widgets: clock, weather, system, media player (with album art & controls),
#          uptime, power buttons, calendar, news, notification status
{ pkgs, lib, theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;

  # Nerd Font icon helper — converts Unicode codepoint to UTF-8 string
  # Usage: nfIcon "F017" → the timer icon
  nfIcon = hex: (builtins.fromJSON ("\"\\u" + hex + "\""));

  # Icons used across widgets (Nerd Font codepoints)
  icons = {
    timer     = nfIcon "F017";  #
    temp      = nfIcon "F2C9";  #
    water     = nfIcon "F043";  #
    wind      = nfIcon "F72E";  #
    sun       = nfIcon "E30D";  #
    cloud     = nfIcon "F0C2";  #
    cloud-sun = nfIcon "F6C4";  #
    fog       = nfIcon "F74E";  #
    rain      = nfIcon "F740";  #
    snow      = nfIcon "F742";  #
    bolt      = nfIcon "F0E7";  #
    drizzle   = nfIcon "F738";  #
    question  = nfIcon "F128";  #
    cpu       = nfIcon "F2DB";  #
    memory    = nfIcon "F538";  #
    disk      = nfIcon "F0A0";  #
    database  = nfIcon "F1C0";  #
    net-up    = nfIcon "F062";  #
    net-down  = nfIcon "F063";  #
    music     = nfIcon "F001";  #
    backward  = nfIcon "F04A";  #
    forward   = nfIcon "F04E";  #
    play      = nfIcon "F04B";  #
    pause     = nfIcon "F04C";  #
    lock      = nfIcon "F023";  #
    sign-out  = nfIcon "F08B";  #
    redo      = nfIcon "F01E";  #
    power     = nfIcon "F011";  #
    calendar  = nfIcon "F073";  #
    newspaper = nfIcon "F1EA";  #
    bell      = nfIcon "F0F3";  #
    gear      = nfIcon "F013";  #
  };

  # ── Scripts ──────────────────────────────────────────────────────────────

  weather-script = pkgs.writeShellScriptBin "eww-weather" ''
    DATA=$(${pkgs.curl}/bin/curl -s --max-time 10 \
      'https://api.open-meteo.com/v1/forecast?latitude=55.75&longitude=37.62&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=Europe/Moscow' 2>/dev/null)
    [[ -z "$DATA" ]] && echo '{"icon":"","desc":"Unavailable","temp":"--","feels":"--","humidity":"--","wind":"--"}' && exit 0

    TEMP=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.temperature_2m')
    FEELS=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.apparent_temperature')
    HUMIDITY=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.relative_humidity_2m')
    WIND=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.wind_speed_10m')
    CODE=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.weather_code')

    case "$CODE" in
      0) ICON=$(printf '\uE30D') DESC="Clear sky" ;;
      1) ICON=$(printf '\uF6C4') DESC="Mainly clear" ;;
      2) ICON=$(printf '\uF6C4') DESC="Partly cloudy" ;;
      3) ICON=$(printf '\uF0C2') DESC="Overcast" ;;
      45|48) ICON=$(printf '\uF74E') DESC="Fog" ;;
      51|53|55) ICON=$(printf '\uF738') DESC="Drizzle" ;;
      61|63|65) ICON=$(printf '\uF740') DESC="Rain" ;;
      66|67) ICON=$(printf '\uF740') DESC="Freezing rain" ;;
      71|73|75) ICON=$(printf '\uF742') DESC="Snow" ;;
      77) ICON=$(printf '\uF742') DESC="Snow grains" ;;
      80|81|82) ICON=$(printf '\uF740') DESC="Showers" ;;
      85|86) ICON=$(printf '\uF742') DESC="Snow showers" ;;
      95|96|99) ICON=$(printf '\uF0E7') DESC="Thunderstorm" ;;
      *) ICON=$(printf '\uF128') DESC="Unknown" ;;
    esac

    ${pkgs.jq}/bin/jq -nc \
      --arg icon "$ICON" --arg desc "$DESC" \
      --arg temp "''${TEMP}°" --arg feels "''${FEELS}°" \
      --arg humidity "''${HUMIDITY}%" --arg wind "''${WIND} km/h" \
      '{icon:$icon, desc:$desc, temp:$temp, feels:$feels, humidity:$humidity, wind:$wind}'
  '';

  sysinfo-script = pkgs.writeShellScriptBin "eww-sysinfo" ''
    net_bytes() {
      ${pkgs.gawk}/bin/awk '/:/ && !/lo:/ {rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev
    }

    read -ra CPU1 <<< "$(head -1 /proc/stat)"
    read -r NET_RX1 NET_TX1 <<< "$(net_bytes)"
    NET_RX1=''${NET_RX1:-0}; NET_TX1=''${NET_TX1:-0}

    sleep 1

    read -ra CPU2 <<< "$(head -1 /proc/stat)"
    read -r NET_RX2 NET_TX2 <<< "$(net_bytes)"
    NET_RX2=''${NET_RX2:-0}; NET_TX2=''${NET_TX2:-0}

    idle1=''${CPU1[4]}; total1=0
    for v in "''${CPU1[@]:1}"; do total1=$((total1 + v)); done
    idle2=''${CPU2[4]}; total2=0
    for v in "''${CPU2[@]:1}"; do total2=$((total2 + v)); done
    dt=$((total2 - total1)); di=$((idle2 - idle1))
    cpu=0; ((dt > 0)) && cpu=$(( (dt - di) * 100 / dt ))

    total_kb=$(${pkgs.gawk}/bin/awk '/^MemTotal:/{print $2}' /proc/meminfo)
    avail_kb=$(${pkgs.gawk}/bin/awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    used_kb=$((total_kb - avail_kb))
    ram=$((used_kb * 100 / total_kb))
    ram_used=$(${pkgs.gawk}/bin/awk "BEGIN{printf \"%.1f\", $used_kb / 1048576}")
    ram_total=$(${pkgs.gawk}/bin/awk "BEGIN{printf \"%.1f\", $total_kb / 1048576}")

    sys_info=$(df -h / | tail -1)
    sys_total_h=$(echo "$sys_info" | ${pkgs.gawk}/bin/awk '{print $2}')
    sys_used_h=$(echo "$sys_info" | ${pkgs.gawk}/bin/awk '{print $3}')
    sys=$(echo "$sys_info" | ${pkgs.gawk}/bin/awk '{gsub(/%/,""); print $5}')

    data_info=$(df -h /home/sakost/dev | tail -1)
    data_total_h=$(echo "$data_info" | ${pkgs.gawk}/bin/awk '{print $2}')
    data_used_h=$(echo "$data_info" | ${pkgs.gawk}/bin/awk '{print $3}')
    data=$(echo "$data_info" | ${pkgs.gawk}/bin/awk '{gsub(/%/,""); print $5}')

    gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo "N/A")

    rx_speed=$((NET_RX2 - NET_RX1))
    tx_speed=$((NET_TX2 - NET_TX1))
    fmt_speed() {
      local b=$1
      if ((b > 1048576)); then
        ${pkgs.gawk}/bin/awk "BEGIN{printf \"%.1f MB/s\", $b / 1048576}"
      elif ((b > 1024)); then
        ${pkgs.gawk}/bin/awk "BEGIN{printf \"%.0f KB/s\", $b / 1024}"
      else
        echo "$b B/s"
      fi
    }
    net_up=$(fmt_speed $tx_speed)
    net_down=$(fmt_speed $rx_speed)

    ${pkgs.jq}/bin/jq -nc \
      --argjson cpu "$cpu" --argjson ram "$ram" \
      --arg ram_used "$ram_used" --arg ram_total "$ram_total" \
      --argjson sys "$sys" --arg sys_used "$sys_used_h" --arg sys_total "$sys_total_h" \
      --argjson data "$data" --arg data_used "$data_used_h" --arg data_total "$data_total_h" \
      --arg gpu "$gpu" --arg net_up "$net_up" --arg net_down "$net_down" \
      '{cpu:$cpu, ram:$ram, ram_used:$ram_used, ram_total:$ram_total, sys:$sys, sys_used:$sys_used, sys_total:$sys_total, data:$data, data_used:$data_used, data_total:$data_total, gpu:$gpu, net_up:$net_up, net_down:$net_down}'
  '';

  player-script = pkgs.writeShellScriptBin "eww-player" ''
    STATUS=$(${pkgs.playerctl}/bin/playerctl status 2>/dev/null || echo "Stopped")
    if [[ "$STATUS" != "Playing" && "$STATUS" != "Paused" ]]; then
      echo '{"status":"Stopped","title":"Not Playing","artist":"","album":"","art":"","position":"0:00","length":"0:00","pct":0,"source":""}'
      exit 0
    fi

    TITLE=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null || echo "")
    ARTIST=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null || echo "")
    ALBUM=$(${pkgs.playerctl}/bin/playerctl metadata album 2>/dev/null || echo "")
    ART_URL=$(${pkgs.playerctl}/bin/playerctl metadata mpris:artUrl 2>/dev/null || echo "")
    ART_URL=''${ART_URL/file:\/\//}
    PLAYER=$(${pkgs.playerctl}/bin/playerctl metadata --format '{{playerName}}' 2>/dev/null || echo "")
    PLAYER_NICE="''${PLAYER^}"

    POS_RAW=$(${pkgs.playerctl}/bin/playerctl position 2>/dev/null || echo "0")
    LEN_US=$(${pkgs.playerctl}/bin/playerctl metadata mpris:length 2>/dev/null || echo "0")
    [[ -z "$POS_RAW" ]] && POS_RAW="0"
    [[ -z "$LEN_US" ]] && LEN_US="0"

    pos_sec=''${POS_RAW%.*}
    len_sec=$((LEN_US / 1000000))
    pos_m=$((pos_sec / 60)); pos_s=$((pos_sec % 60))
    len_m=$((len_sec / 60)); len_s=$((len_sec % 60))
    pct=0; ((len_sec > 0)) && pct=$((pos_sec * 100 / len_sec))

    POS_FMT=$(printf '%d:%02d' $pos_m $pos_s)
    LEN_FMT=$(printf '%d:%02d' $len_m $len_s)

    ${pkgs.jq}/bin/jq -nc \
      --arg status "$STATUS" --arg title "$TITLE" --arg artist "$ARTIST" \
      --arg album "$ALBUM" --arg art "$ART_URL" \
      --arg position "$POS_FMT" --arg length "$LEN_FMT" \
      --argjson pct "$pct" --arg source "$PLAYER_NICE" \
      '{status:$status, title:$title, artist:$artist, album:$album, art:$art, position:$position, length:$length, pct:$pct, source:$source}'
  '';

  calendar-script = pkgs.writeShellScriptBin "eww-calendar" ''
    strip_ansi() { sed 's/\x1b\[[0-9;]*m//g'; }
    OUTPUT=$(${pkgs.gcalcli}/bin/gcalcli agenda --nocolor --nodeclined 2>/dev/null | strip_ansi)
    if [[ -z "$OUTPUT" ]] || echo "$OUTPUT" | grep -q "No Events Found"; then
      echo "No upcoming events"
    else
      echo "$OUTPUT" | head -12
    fi
  '';

  mako-status-script = pkgs.writeShellScriptBin "eww-mako-status" ''
    MODES=$(${pkgs.mako}/bin/makoctl mode 2>/dev/null)
    DND="off"; WORK="off"
    echo "$MODES" | grep -q "dnd" && DND="on"
    echo "$MODES" | grep -q "work" && WORK="on"
    echo "DND: $DND  |  Work: $WORK"
  '';

  news-script = pkgs.writeShellScriptBin "eww-news" ''
    ${pkgs.curl}/bin/curl -s 'https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=7' \
      | ${pkgs.jq}/bin/jq -r '.hits[] | "\(.title)"' 2>/dev/null || echo "News unavailable"
  '';

  uptime-script = pkgs.writeShellScriptBin "eww-uptime" ''
    uptime -p | sed 's/up //'
  '';

  greeting-script = pkgs.writeShellScriptBin "eww-greeting" ''
    HOUR=$(date +%H)
    if ((HOUR >= 5 && HOUR < 12)); then
      echo "Good morning, sakost"
    elif ((HOUR >= 12 && HOUR < 17)); then
      echo "Good afternoon, sakost"
    elif ((HOUR >= 17 && HOUR < 22)); then
      echo "Good evening, sakost"
    else
      echo "Good night, sakost"
    fi
  '';

  # Toggle script for keybinding
  toggle-script = pkgs.writeShellScriptBin "eww-toggle-dashboard" ''
    STATE=$(${pkgs.eww}/bin/eww get dashboard_open 2>/dev/null || echo "false")
    if [[ "$STATE" == "true" ]]; then
      ${pkgs.eww}/bin/eww close dashboard
      ${pkgs.eww}/bin/eww update dashboard_open=false
    else
      ${pkgs.eww}/bin/eww open dashboard
      ${pkgs.eww}/bin/eww update dashboard_open=true
    fi
  '';

  # Volume OSD script — called from Hyprland keybindings
  # Usage: eww-volume-osd [raise|lower|mute|mic-mute]
  volume-osd-script = pkgs.writeShellScriptBin "eww-volume-osd" ''
    EWW="${pkgs.eww}/bin/eww"
    WPCTL="${pkgs.wireplumber}/bin/wpctl"
    LOCK="/tmp/eww-osd-timer.lock"

    case "$1" in
      raise)   $WPCTL set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
      lower)   $WPCTL set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
      mute)    $WPCTL set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
      mic-mute) $WPCTL set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
    esac

    # Read current state
    SINK_INFO=$($WPCTL get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    VOL=$(echo "$SINK_INFO" | ${pkgs.gawk}/bin/awk '{printf "%.0f", $2 * 100}')
    MUTED=$(echo "$SINK_INFO" | grep -q MUTED && echo "true" || echo "false")

    SOURCE_INFO=$($WPCTL get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
    MIC_VOL=$(echo "$SOURCE_INFO" | ${pkgs.gawk}/bin/awk '{printf "%.0f", $2 * 100}')
    MIC_MUTED=$(echo "$SOURCE_INFO" | grep -q MUTED && echo "true" || echo "false")

    # Pick icon (use printf for Nerd Font glyphs to survive Nix string interpolation)
    ICON_VOL_HIGH=$(printf '\U000f057e')   # 󰕾
    ICON_VOL_MED=$(printf '\U000f0580')    # 󰖀
    ICON_VOL_LOW=$(printf '\U000f057f')    # 󰕿
    ICON_VOL_MUTE=$(printf '\U000f0581')   # 󰖁
    ICON_VOL_OFF=$(printf '\U000f0e08')    # 󰸈
    ICON_MIC=$(printf '\U000f036c')        # 󰍬
    ICON_MIC_OFF=$(printf '\U000f036d')    # 󰍭

    if [[ "$1" == "mic-mute" ]]; then
      if [[ "$MIC_MUTED" == "true" ]]; then
        ICON="$ICON_MIC_OFF"; OSD_VAL=$MIC_VOL
      else
        ICON="$ICON_MIC"; OSD_VAL=$MIC_VOL
      fi
      OSD_CLASS="osd-mic"
    else
      if [[ "$MUTED" == "true" ]]; then
        ICON="$ICON_VOL_MUTE"; OSD_VAL=$VOL
      elif ((VOL >= 66)); then
        ICON="$ICON_VOL_HIGH"; OSD_VAL=$VOL
      elif ((VOL >= 33)); then
        ICON="$ICON_VOL_MED"; OSD_VAL=$VOL
      elif ((VOL > 0)); then
        ICON="$ICON_VOL_LOW"; OSD_VAL=$VOL
      else
        ICON="$ICON_VOL_OFF"; OSD_VAL=0
      fi
      OSD_CLASS="osd-vol"
    fi

    # Detect focused monitor for OSD placement
    FOCUSED_MON=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

    # Update eww and show OSD on focused monitor
    $EWW update osd_icon="$ICON" osd_value="$OSD_VAL" osd_class="$OSD_CLASS"
    $EWW close volume_osd 2>/dev/null
    $EWW open volume_osd --screen "$FOCUSED_MON" 2>/dev/null

    # Auto-hide after 2s (kill previous timer)
    PID_FILE="/tmp/eww-osd-pid"
    [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" 2>/dev/null
    ( sleep 2; $EWW close volume_osd 2>/dev/null ) &
    echo $! > "$PID_FILE"
  '';

  # Brightness OSD script — called from Hyprland keybindings
  # Usage: eww-brightness-osd [raise|lower]
  # Uses ddcutil for external monitors (no backlight on desktop)
  brightness-osd-script = pkgs.writeShellScriptBin "eww-brightness-osd" ''
    EWW="${pkgs.eww}/bin/eww"
    DDC="${pkgs.ddcutil}/bin/ddcutil"
    CACHE="/tmp/eww-brightness-cache"

    ICON_HIGH=$(printf '\U000f00df')   # 󰃟 brightness-high
    ICON_MED=$(printf '\U000f00de')    # 󰃞 brightness-medium
    ICON_LOW=$(printf '\U000f00dd')    # 󰃝 brightness-low

    BRIGHTNESS=""

    # Try laptop backlight first (only if actual backlight device exists, not just LEDs)
    BL=$(${pkgs.brightnessctl}/bin/brightnessctl -c backlight -l 2>/dev/null | grep -oP "Device '\K[^']+")
    if [ -n "$BL" ]; then
      case "$1" in
        raise) ${pkgs.brightnessctl}/bin/brightnessctl -c backlight set 5%+ ;;
        lower) ${pkgs.brightnessctl}/bin/brightnessctl -c backlight set 5%- ;;
      esac
      BRIGHTNESS=$(${pkgs.brightnessctl}/bin/brightnessctl -c backlight -m | cut -d, -f4 | tr -d %)
    fi

    # DDC/CI for external monitors (VCP feature 0x10 = brightness)
    if [ -z "$BRIGHTNESS" ]; then
      # Read cached value or query DDC (slow ~0.5s)
      CURRENT=""
      DDC_VAL=$($DDC getvcp 10 2>/dev/null | grep -oP 'current value =\s*\K\d+')
      if [ -n "$DDC_VAL" ]; then
        CURRENT=$DDC_VAL
      elif [ -f "$CACHE" ]; then
        CURRENT=$(cat "$CACHE")
      fi

      # If we still can't read it, nothing we can do
      [ -z "$CURRENT" ] && exit 1

      case "$1" in
        raise) NEW=$(( CURRENT + 5 > 100 ? 100 : CURRENT + 5 )) ;;
        lower) NEW=$(( CURRENT - 5 < 0 ? 0 : CURRENT - 5 )) ;;
        *)     NEW=$CURRENT ;;
      esac

      $DDC setvcp 10 "$NEW" 2>/dev/null
      echo "$NEW" > "$CACHE"
      BRIGHTNESS=$NEW
    fi

    [ -z "$BRIGHTNESS" ] && exit 1

    # Pick icon
    if [ "$BRIGHTNESS" -ge 66 ]; then
      ICON="$ICON_HIGH"
    elif [ "$BRIGHTNESS" -ge 33 ]; then
      ICON="$ICON_MED"
    else
      ICON="$ICON_LOW"
    fi

    # Detect focused monitor for OSD placement
    FOCUSED_MON=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

    $EWW update osd_icon="$ICON" osd_value="$BRIGHTNESS" osd_class="osd-bright"
    $EWW close brightness_osd 2>/dev/null
    $EWW open brightness_osd --screen "$FOCUSED_MON" 2>/dev/null

    # Auto-hide after 2s
    PID_FILE="/tmp/eww-bright-osd-pid"
    [[ -f "$PID_FILE" ]] && kill "$(cat "$PID_FILE")" 2>/dev/null
    ( sleep 2; $EWW close brightness_osd 2>/dev/null ) &
    echo $! > "$PID_FILE"
  '';
in
{
  home.packages = [
    pkgs.eww
    pkgs.gcalcli
    pkgs.playerctl
    weather-script
    news-script
    sysinfo-script
    player-script
    calendar-script
    mako-status-script
    uptime-script
    greeting-script
    toggle-script
    volume-osd-script
    brightness-osd-script
    pkgs.ddcutil
  ];

  xdg.configFile."eww/eww.yuck".text = ''
    ;; ── State ──
    (defvar dashboard_open false)
    (defvar osd_icon "")
    (defvar osd_value 0)
    (defvar osd_class "osd-vol")

    ;; ── Polled variables ──
    (defpoll time_val :interval "1s" :initial "00:00" `date '+%H:%M'`)
    (defpoll time_sec :interval "1s" :initial "00" `date '+%S'`)
    (defpoll date_val :interval "60s" :initial "" `date '+%A, %B %d'`)
    (defpoll greeting :interval "300s" :initial "" `${greeting-script}/bin/eww-greeting`)
    (defpoll uptime_val :interval "30s" :initial "" `${uptime-script}/bin/eww-uptime`)

    (defpoll weather :interval "1800s"
      :initial '{"icon":"","desc":"Loading...","temp":"--","feels":"--","humidity":"--","wind":"--"}'
      `${weather-script}/bin/eww-weather`)

    (defpoll sysinfo :interval "3s"
      :initial '{"cpu":0,"ram":0,"ram_used":"0","ram_total":"0","sys":0,"sys_used":"--","sys_total":"--","data":0,"data_used":"--","data_total":"--","gpu":"--","net_up":"--","net_down":"--"}'
      `${sysinfo-script}/bin/eww-sysinfo`)

    (defpoll player :interval "1s"
      :initial '{"status":"Stopped","title":"Not Playing","artist":"","album":"","art":"","position":"0:00","length":"0:00","pct":0,"source":""}'
      `${player-script}/bin/eww-player`)

    (defpoll calendar_val :interval "300s" :initial "Loading..." `${calendar-script}/bin/eww-calendar`)
    (defpoll news_val :interval "600s" :initial "Loading..." `${news-script}/bin/eww-news`)
    (defpoll mako_val :interval "5s" :initial "DND: off  |  Work: off" `${mako-status-script}/bin/eww-mako-status`)

    ;; ── Reusable metric bar ──
    (defwidget metric [label value text ?icon ?css-class]
      (box :class "metric ''${css-class}" :orientation "h" :space-evenly false
        (label :class "metric-icon" :text {icon ?: ""})
        (label :class "metric-label" :text label)
        (scale :class "metric-scale" :min 0 :max 100 :value value :active false :orientation "h" :hexpand true)
        (label :class "metric-text" :text text)))

    ;; ── Dashboard ──
    (defwidget dashboard []
      (box :class "dashboard" :orientation "h" :space-evenly false :halign "center" :valign "center"
        ;; Left column
        (box :class "col col-left" :orientation "v" :space-evenly false
          (clock-widget)
          (weather-widget)
          (power-widget))
        ;; Center column
        (box :class "col col-center" :orientation "v" :space-evenly false
          (player-widget)
          (sysinfo-widget))
        ;; Right column
        (box :class "col col-right" :orientation "v" :space-evenly false
          (calendar-widget)
          (news-widget)
          (mako-widget))))

    ;; ── Clock ──
    (defwidget clock-widget []
      (box :class "card clock-card" :orientation "v" :space-evenly false
        (label :class "greeting" :halign "start" :text greeting)
        (box :class "time-row" :orientation "h" :space-evenly false :halign "start"
          (label :class "time" :text time_val)
          (label :class "time-sec" :text time_sec))
        (label :class "date" :halign "start" :text date_val)
        (box :class "uptime-row" :orientation "h" :space-evenly false :halign "start"
          (label :class "uptime-icon" :text "${icons.timer}")
          (label :class "uptime-text" :text uptime_val))))

    ;; ── Weather ──
    (defwidget weather-widget []
      (box :class "card weather-card" :orientation "v" :space-evenly false
        (box :orientation "h" :space-evenly false
          (label :class "weather-icon" :text {weather.icon})
          (box :orientation "v" :space-evenly false :hexpand true
            (label :class "weather-temp" :halign "start" :text {weather.temp})
            (label :class "weather-desc" :halign "start" :text {weather.desc})))
        (box :class "weather-details" :orientation "h" :space-evenly true
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "weather-detail-icon" :text "${icons.temp}")
            (label :class "weather-detail-text" :text "feels ''${weather.feels}"))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "weather-detail-icon" :text "${icons.water}")
            (label :class "weather-detail-text" :text {weather.humidity}))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "weather-detail-icon" :text "${icons.wind}")
            (label :class "weather-detail-text" :text {weather.wind})))))

    ;; ── System Info ──
    (defwidget sysinfo-widget []
      (box :class "card sysinfo-card" :orientation "v" :space-evenly false
        (label :class "card-title" :halign "start" :text "${icons.gear}  System")
        (metric :label "CPU" :value {sysinfo.cpu} :text "''${sysinfo.cpu}%" :icon "${icons.cpu}" :css-class "metric-cpu")
        (metric :label "RAM" :value {sysinfo.ram} :text "''${sysinfo.ram_used}G / ''${sysinfo.ram_total}G" :icon "${icons.memory}" :css-class "metric-ram")
        (metric :label "SYS" :value {sysinfo.sys} :text "''${sysinfo.sys_used} / ''${sysinfo.sys_total}" :icon "${icons.disk}" :css-class "metric-sys")
        (metric :label "DATA" :value {sysinfo.data} :text "''${sysinfo.data_used} / ''${sysinfo.data_total}" :icon "${icons.database}" :css-class "metric-data")
        (box :class "sys-footer" :orientation "h" :space-evenly true
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "sys-footer-icon gpu-icon" :text "󰢮")
            (label :class "sys-footer-text" :text "''${sysinfo.gpu}°C"))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "sys-footer-icon net-icon" :text "${icons.net-up}")
            (label :class "sys-footer-text" :text "↑''${sysinfo.net_up}"))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "sys-footer-icon net-icon" :text "${icons.net-down}")
            (label :class "sys-footer-text" :text "↓''${sysinfo.net_down}")))))

    ;; ── Media Player (with album art & controls) ──
    (defwidget player-widget []
      (box :class "card player-card" :orientation "h" :space-evenly false
        :visible {player.status != "Stopped"}
        ;; Album art
        (box :class "album-art"
          :style {player.art != "" ? "background-image: url('''''${player.art}');" : ""}
          :visible {player.art != ""}
          :width 180 :height 180)
        ;; No art placeholder
        (box :class "album-art album-art-placeholder"
          :visible {player.art == ""}
          :width 180 :height 180
          (label :class "album-art-icon" :text "${icons.music}"))
        ;; Info + controls
        (box :class "player-info" :orientation "v" :space-evenly false :hexpand true
          ;; Source badge
          (label :class "player-source" :halign "start"
            :text {player.source != "" ? "via ''${player.source}" : ""})
          ;; Title & artist
          (label :class "player-title" :halign "start" :limit-width 30 :text {player.title})
          (label :class "player-artist" :halign "start" :limit-width 35
            :text {player.album != "" ? "''${player.artist}  ''${player.album}" : player.artist})
          ;; Progress
          (box :class "player-progress" :orientation "v" :space-evenly false
            (scale :class "player-scale" :min 0 :max 100 :value {player.pct} :active false :orientation "h")
            (box :orientation "h" :space-evenly false
              (label :class "player-time" :halign "start" :text {player.position} :hexpand true)
              (label :class "player-time" :halign "end" :text {player.length})))
          ;; Controls
          (box :class "player-controls" :orientation "h" :space-evenly true :halign "center"
            (button :class "ctrl-btn" :onclick "${pkgs.playerctl}/bin/playerctl previous" "${icons.backward}")
            (button :class "play-btn" :onclick "${pkgs.playerctl}/bin/playerctl play-pause"
              {player.status == "Playing" ? "${icons.pause}" : "${icons.play}"})
            (button :class "ctrl-btn" :onclick "${pkgs.playerctl}/bin/playerctl next" "${icons.forward}")))))

    ;; ── Power Buttons ──
    (defwidget power-widget []
      (box :class "card power-card" :orientation "h" :space-evenly true
        (button :class "power-btn lock-btn" :onclick "${pkgs.hyprlock}/bin/hyprlock &" "${icons.lock}")
        (button :class "power-btn logout-btn" :onclick "loginctl terminate-user sakost" "${icons.sign-out}")
        (button :class "power-btn reboot-btn" :onclick "systemctl reboot" "${icons.redo}")
        (button :class "power-btn shutdown-btn" :onclick "systemctl poweroff" "${icons.power}")))

    ;; ── Calendar ──
    (defwidget calendar-widget []
      (box :class "card calendar-card" :orientation "v" :space-evenly false
        (label :class "card-title" :halign "start" :text "${icons.calendar}  Calendar")
        (label :class "card-content calendar-text" :text calendar_val :wrap true)))

    ;; ── News ──
    (defwidget news-widget []
      (box :class "card news-card" :orientation "v" :space-evenly false
        (label :class "card-title" :halign "start" :text "${icons.newspaper}  Hacker News")
        (label :class "card-content news-text" :text news_val :wrap true)))

    ;; ── Mako Status ──
    (defwidget mako-widget []
      (box :class "mako-status" :orientation "h" :space-evenly false :halign "center"
        (label :class "mako-icon" :text "${icons.bell}")
        (label :class "mako-text" :text mako_val)))

    ;; ── Volume/Mic OSD ──
    (defwidget osd-widget []
      (box :class "osd-container ''${osd_class}" :orientation "h" :space-evenly false
           :valign "center" :halign "center"
        (label :class "osd-icon" :text osd_icon)
        (scale :class "osd-scale" :min 0 :max 100 :value osd_value :active false :orientation "h")
        (label :class "osd-text" :text "''${osd_value}%")))

    (defwindow volume_osd
      :monitor "DP-2"
      :geometry (geometry :x "0%" :y "85%" :width "320px" :height "60px" :anchor "top center")
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "volume_osd"
      (osd-widget))

    (defwindow brightness_osd
      :monitor "DP-2"
      :geometry (geometry :x "0%" :y "85%" :width "320px" :height "60px" :anchor "top center")
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "brightness_osd"
      (osd-widget))

    ;; ── USB Popup ──
    (defvar usb_icon "")
    (defvar usb_title "Device Connected")
    (defvar usb_desc "")

    (defwidget usb-popup-widget []
      (box :class "usb-container" :orientation "h" :space-evenly false
           :valign "center" :halign "center"
        (label :class "usb-icon" :text usb_icon)
        (box :orientation "v" :space-evenly false
          (label :class "usb-title" :halign "start" :text usb_title)
          (label :class "usb-desc" :halign "start" :text usb_desc))))

    (defwindow usb_popup
      :monitor "DP-2"
      :geometry (geometry :x "0%" :y "5%" :width "380px" :height "70px" :anchor "top center")
      :stacking "overlay"
      :exclusive false
      :focusable false
      :namespace "usb_popup"
      (usb-popup-widget))

    ;; ── Window ──
    (defwindow dashboard
      :monitor "HDMI-A-1"
      :geometry (geometry :x "0%" :y "0%" :width "100%" :height "100%")
      :stacking "bottom"
      :exclusive false
      :focusable false
      (dashboard))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    // TokyoNight glassmorphic palette
    $bg: ${c.bg};
    $bg-dark: ${c.bg-dark};
    $bg-light: ${c.bg-light};
    $surface0: ${c.surface0};
    $surface1: ${c.surface1};
    $surface2: ${c.surface2};
    $fg: ${c.fg};
    $fg-dim: ${c.fg-dim};
    $fg-dark: ${c.fg-dark};
    $accent: ${c.accent};
    $blue: ${c.blue};
    $magenta: ${c.magenta};
    $cyan: ${c.cyan};
    $green: ${c.green};
    $yellow: ${c.yellow};
    $red: ${c.red};
    $orange: ${c.orange};
    $teal: ${c.teal};
    $white: ${c.white};

    // Glass mixins
    $glass-bg: ${rgba c.bg-light 0.55};
    $glass-border: ${rgba c.accent 0.15};
    $glass-glow: ${rgba c.accent 0.08};

    * {
      all: unset;
      font-family: "${theme.fonts.mono}", monospace;
    }

    // ── Layout ──
    .dashboard {
      padding: 48px 40px;
    }

    .col {
      margin: 0 10px;
    }
    .col-left {
      min-width: 420px;
    }
    .col-center {
      min-width: 520px;
    }
    .col-right {
      min-width: 380px;
    }

    // ── Glass card ──
    .card {
      background-color: $glass-bg;
      border-radius: ${toString theme.border.radius.large}px;
      border: 1px solid $glass-border;
      padding: 22px 26px;
      margin-bottom: 14px;
      box-shadow: 0 8px 32px ${rgba c.bg-dark 0.4};
    }

    .card-title {
      font-size: 14px;
      font-weight: bold;
      color: $accent;
      margin-bottom: 12px;
    }

    .card-content {
      font-size: 13px;
      color: $fg;
    }

    // ── Clock ──
    .clock-card {
      padding: 30px 30px 24px;
      border-left: 3px solid $accent;
    }

    .greeting {
      font-size: 16px;
      color: $fg-dim;
      margin-bottom: 4px;
      font-weight: 500;
    }

    .time-row {
      margin: 4px 0;
    }

    .time {
      font-size: 72px;
      font-weight: 900;
      color: $fg;
    }

    .time-sec {
      font-size: 28px;
      font-weight: bold;
      color: $accent;
      margin-left: 6px;
      margin-top: 36px;
    }

    .date {
      font-size: 16px;
      color: $magenta;
      font-weight: 600;
      margin-top: 2px;
    }

    .uptime-row {
      margin-top: 14px;
      padding-top: 12px;
      border-top: 1px solid ${rgba c.surface1 0.5};
    }

    .uptime-icon {
      font-size: 14px;
      color: $fg-dark;
      margin-right: 8px;
    }

    .uptime-text {
      font-size: 13px;
      color: $fg-dark;
    }

    // ── Weather ──
    .weather-card {
      border-left: 3px solid $cyan;
    }

    .weather-icon {
      font-size: 56px;
      color: $cyan;
      margin-right: 20px;
      min-width: 70px;
    }

    .weather-temp {
      font-size: 36px;
      font-weight: 900;
      color: $fg;
    }

    .weather-desc {
      font-size: 14px;
      color: $fg-dim;
      margin-top: 2px;
    }

    .weather-details {
      margin-top: 16px;
      padding-top: 14px;
      border-top: 1px solid ${rgba c.surface1 0.5};
    }

    .weather-detail-icon {
      font-size: 14px;
      color: $cyan;
      margin-right: 6px;
    }

    .weather-detail-text {
      font-size: 12px;
      color: $fg-dim;
    }

    // ── System Info ──
    .sysinfo-card {
      border-left: 3px solid $green;
    }

    .metric {
      margin: 4px 0;
    }

    .metric-icon {
      font-size: 14px;
      min-width: 22px;
      margin-right: 4px;
    }

    .metric-label {
      font-size: 11px;
      color: $fg-dark;
      min-width: 40px;
      font-weight: bold;
    }

    .metric-text {
      font-size: 11px;
      color: $fg-dim;
      min-width: 130px;
      margin-left: 10px;
    }

    .metric-scale trough {
      background-color: ${rgba c.surface0 0.8};
      border-radius: 4px;
      min-height: 6px;
    }

    .metric-scale slider {
      all: unset;
      margin: 0; padding: 0; min-width: 0; min-height: 0;
      background-color: transparent;
    }

    // Per-metric colors
    .metric-cpu .metric-icon { color: $red; }
    .metric-cpu .metric-scale trough highlight {
      background-color: $red;
      border-radius: 4px; min-height: 6px;
    }

    .metric-ram .metric-icon { color: $green; }
    .metric-ram .metric-scale trough highlight {
      background-color: $green;
      border-radius: 4px; min-height: 6px;
    }

    .metric-sys .metric-icon { color: $blue; }
    .metric-sys .metric-scale trough highlight {
      background-color: $blue;
      border-radius: 4px; min-height: 6px;
    }

    .metric-data .metric-icon { color: $magenta; }
    .metric-data .metric-scale trough highlight {
      background-color: $magenta;
      border-radius: 4px; min-height: 6px;
    }

    .sys-footer {
      margin-top: 10px;
      padding-top: 10px;
      border-top: 1px solid ${rgba c.surface1 0.5};
    }

    .sys-footer-icon {
      font-size: 14px;
      margin-right: 6px;
    }

    .gpu-icon { color: $green; }
    .net-icon { color: $cyan; }

    .sys-footer-text {
      font-size: 11px;
      color: $fg-dim;
    }

    // ── Media Player ──
    .player-card {
      padding: 18px 22px;
      border-left: 3px solid $magenta;
    }

    .album-art {
      background-size: cover;
      background-repeat: no-repeat;
      background-position: center;
      border-radius: 12px;
      min-width: 180px;
      min-height: 180px;
      margin-right: 22px;
      box-shadow: 0 4px 20px ${rgba c.bg-dark 0.6};
    }

    .album-art-placeholder {
      background-color: ${rgba c.surface0 0.6};
    }

    .album-art-icon {
      font-size: 48px;
      color: $fg-dark;
    }

    .player-info {
      padding: 4px 0;
    }

    .player-source {
      font-size: 10px;
      color: $yellow;
      font-weight: bold;
      margin-bottom: 6px;
    }

    .player-title {
      font-size: 18px;
      font-weight: 900;
      color: $fg;
    }

    .player-artist {
      font-size: 13px;
      color: $magenta;
      margin-top: 3px;
      font-weight: 600;
    }

    .player-progress {
      margin-top: 14px;
    }

    .player-scale trough {
      background-color: ${rgba c.surface0 0.8};
      border-radius: 4px;
      min-height: 5px;
    }

    .player-scale trough highlight {
      background-color: $magenta;
      border-radius: 4px;
      min-height: 5px;
    }

    .player-scale slider {
      all: unset;
      margin: 0; padding: 0; min-width: 0; min-height: 0;
      background-color: transparent;
    }

    .player-time {
      font-size: 10px;
      color: $fg-dark;
      margin-top: 4px;
    }

    .player-controls {
      margin-top: 12px;
      min-width: 180px;
    }

    .ctrl-btn {
      font-size: 22px;
      color: $fg-dark;
      transition: color 0.2s;
    }
    .ctrl-btn:hover {
      color: $fg;
    }

    .play-btn {
      font-size: 36px;
      color: $magenta;
      transition: color 0.2s;
    }
    .play-btn:hover {
      color: $accent;
    }

    // ── Power Buttons ──
    .power-card {
      padding: 18px 24px;
    }

    .power-btn {
      font-size: 28px;
      padding: 12px 20px;
      border-radius: 12px;
      background-color: ${rgba c.surface0 0.4};
      transition: background-color 0.2s;
    }
    .power-btn:hover {
      background-color: ${rgba c.surface1 0.6};
    }

    .lock-btn { color: $blue; }
    .logout-btn { color: $green; }
    .reboot-btn { color: $yellow; }
    .shutdown-btn { color: $red; }

    // ── Calendar ──
    .calendar-card {
      border-left: 3px solid $yellow;
    }

    .calendar-text {
      font-size: 12px;
      /* line-height not supported in GTK CSS */
    }

    // ── News ──
    .news-card {
      border-left: 3px solid $orange;
    }

    .news-text {
      font-size: 12px;
      /* line-height not supported in GTK CSS */
    }

    // ── Volume/Mic OSD ──
    .osd-container {
      background-color: ${rgba c.bg-light 0.88};
      border: 1px solid ${rgba c.white 0.05};
      border-radius: ${toString theme.border.radius.pill}px;
      padding: 0px 25px;
      box-shadow: 0 4px 16px ${rgba c.bg-dark 0.5};
    }

    .osd-icon {
      font-size: 24px;
      margin-right: 15px;
    }

    .osd-vol .osd-icon {
      color: $accent;
    }

    .osd-mic .osd-icon {
      color: $red;
    }

    .osd-text {
      font-weight: 800;
      font-size: 16px;
      color: $fg;
      margin-left: 15px;
      min-width: 45px;
    }

    .osd-scale {
      min-width: 180px;
    }

    .osd-scale trough {
      all: unset;
      background-color: ${rgba c.bg-dark 0.6};
      border-radius: ${toString theme.border.radius.pill}px;
      min-height: 8px;
      margin-top: 26px;
      margin-bottom: 26px;
    }

    .osd-vol .osd-scale trough highlight {
      all: unset;
      background-color: $accent;
      border-radius: ${toString theme.border.radius.pill}px;
      min-height: 8px;
    }

    .osd-mic .osd-scale trough highlight {
      all: unset;
      background-color: $red;
      border-radius: ${toString theme.border.radius.pill}px;
      min-height: 8px;
    }

    .osd-bright .osd-icon {
      color: $yellow;
    }

    .osd-bright .osd-scale trough highlight {
      all: unset;
      background-color: $yellow;
      border-radius: ${toString theme.border.radius.pill}px;
      min-height: 8px;
    }

    // ── USB Popup ──
    .usb-container {
      background-color: $glass-bg;
      border: 1px solid $glass-border;
      border-radius: ${toString theme.border.radius.large}px;
      padding: 14px 22px;
      box-shadow: 0 4px 16px ${rgba c.bg-dark 0.5};
    }

    .usb-icon {
      font-size: 32px;
      color: $teal;
      margin-right: 16px;
      min-width: 40px;
    }

    .usb-title {
      font-size: 14px;
      font-weight: bold;
      color: $fg;
    }

    .usb-desc {
      font-size: 12px;
      color: $fg-dim;
      margin-top: 2px;
    }

    // ── Mako Status ──
    .mako-status {
      padding: 8px 0;
    }

    .mako-icon {
      font-size: 14px;
      color: $fg-dark;
      margin-right: 8px;
    }

    .mako-text {
      font-size: 12px;
      color: $fg-dark;
    }
  '';
}
