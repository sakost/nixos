# Eww glassmorphic dashboard overlay for HDMI-A-1
# Widgets: clock, weather, system, media player (with album art & controls),
#          uptime, power buttons, calendar, news, notification status
{ pkgs, lib, theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;

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
      0) ICON="" DESC="Clear sky" ;;
      1) ICON="" DESC="Mainly clear" ;;
      2) ICON="" DESC="Partly cloudy" ;;
      3) ICON="" DESC="Overcast" ;;
      45|48) ICON="" DESC="Fog" ;;
      51|53|55) ICON="" DESC="Drizzle" ;;
      61|63|65) ICON="" DESC="Rain" ;;
      66|67) ICON="" DESC="Freezing rain" ;;
      71|73|75) ICON="" DESC="Snow" ;;
      77) ICON="" DESC="Snow grains" ;;
      80|81|82) ICON="" DESC="Showers" ;;
      85|86) ICON="" DESC="Snow showers" ;;
      95|96|99) ICON="" DESC="Thunderstorm" ;;
      *) ICON="" DESC="Unknown" ;;
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
  ];

  xdg.configFile."eww/eww.yuck".text = ''
    ;; ── State ──
    (defvar dashboard_open false)

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
          (label :class "uptime-icon" :text "")
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
            (label :class "weather-detail-icon" :text "")
            (label :class "weather-detail-text" :text "feels ''${weather.feels}"))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "weather-detail-icon" :text "")
            (label :class "weather-detail-text" :text {weather.humidity}))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "weather-detail-icon" :text "")
            (label :class "weather-detail-text" :text {weather.wind})))))

    ;; ── System Info ──
    (defwidget sysinfo-widget []
      (box :class "card sysinfo-card" :orientation "v" :space-evenly false
        (label :class "card-title" :halign "start" :text "  System")
        (metric :label "CPU" :value {sysinfo.cpu} :text "''${sysinfo.cpu}%" :icon "" :css-class "metric-cpu")
        (metric :label "RAM" :value {sysinfo.ram} :text "''${sysinfo.ram_used}G / ''${sysinfo.ram_total}G" :icon "" :css-class "metric-ram")
        (metric :label "SYS" :value {sysinfo.sys} :text "''${sysinfo.sys_used} / ''${sysinfo.sys_total}" :icon "" :css-class "metric-sys")
        (metric :label "DATA" :value {sysinfo.data} :text "''${sysinfo.data_used} / ''${sysinfo.data_total}" :icon "" :css-class "metric-data")
        (box :class "sys-footer" :orientation "h" :space-evenly true
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "sys-footer-icon gpu-icon" :text "󰢮")
            (label :class "sys-footer-text" :text "''${sysinfo.gpu}°C"))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "sys-footer-icon net-icon" :text "")
            (label :class "sys-footer-text" :text "↑''${sysinfo.net_up}"))
          (box :orientation "h" :space-evenly false :halign "center"
            (label :class "sys-footer-icon net-icon" :text "")
            (label :class "sys-footer-text" :text "↓''${sysinfo.net_down}")))))

    ;; ── Media Player (with album art & controls) ──
    (defwidget player-widget []
      (box :class "card player-card" :orientation "h" :space-evenly false
        :visible {player.status != "Stopped"}
        ;; Album art
        (box :class "album-art"
          :style "background-image: url('''''${player.art}');"
          :visible {player.art != ""}
          :width 180 :height 180)
        ;; No art placeholder
        (box :class "album-art album-art-placeholder"
          :visible {player.art == ""}
          :width 180 :height 180
          (label :class "album-art-icon" :text ""))
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
            (button :class "ctrl-btn" :onclick "${pkgs.playerctl}/bin/playerctl previous" "")
            (button :class "play-btn" :onclick "${pkgs.playerctl}/bin/playerctl play-pause"
              {player.status == "Playing" ? "" : ""})
            (button :class "ctrl-btn" :onclick "${pkgs.playerctl}/bin/playerctl next" "")))))

    ;; ── Power Buttons ──
    (defwidget power-widget []
      (box :class "card power-card" :orientation "h" :space-evenly true
        (button :class "power-btn lock-btn" :onclick "${pkgs.hyprlock}/bin/hyprlock &" "")
        (button :class "power-btn logout-btn" :onclick "loginctl terminate-user sakost" "")
        (button :class "power-btn reboot-btn" :onclick "systemctl reboot" "")
        (button :class "power-btn shutdown-btn" :onclick "systemctl poweroff" "")))

    ;; ── Calendar ──
    (defwidget calendar-widget []
      (box :class "card calendar-card" :orientation "v" :space-evenly false
        (label :class "card-title" :halign "start" :text "  Calendar")
        (label :class "card-content calendar-text" :text calendar_val :wrap true)))

    ;; ── News ──
    (defwidget news-widget []
      (box :class "card news-card" :orientation "v" :space-evenly false
        (label :class "card-title" :halign "start" :text "  Hacker News")
        (label :class "card-content news-text" :text news_val :wrap true)))

    ;; ── Mako Status ──
    (defwidget mako-widget []
      (box :class "mako-status" :orientation "h" :space-evenly false :halign "center"
        (label :class "mako-icon" :text "")
        (label :class "mako-text" :text mako_val)))

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
      box-shadow: inset 0 1px 0 0 ${rgba c.white 0.06},
                  0 8px 32px ${rgba c.bg-dark 0.4};
    }

    .card-title {
      font-size: 14px;
      font-weight: bold;
      color: $accent;
      margin-bottom: 12px;
      letter-spacing: 0.5px;
    }

    .card-content {
      font-size: 13px;
      color: $fg;
      line-height: 1.5;
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
      letter-spacing: -2px;
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
      text-transform: uppercase;
      letter-spacing: 0.5px;
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
      background-image: linear-gradient(to right, $red, $orange);
      border-radius: 4px; min-height: 6px;
    }

    .metric-ram .metric-icon { color: $green; }
    .metric-ram .metric-scale trough highlight {
      background-image: linear-gradient(to right, $green, $teal);
      border-radius: 4px; min-height: 6px;
    }

    .metric-sys .metric-icon { color: $blue; }
    .metric-sys .metric-scale trough highlight {
      background-image: linear-gradient(to right, $blue, $cyan);
      border-radius: 4px; min-height: 6px;
    }

    .metric-data .metric-icon { color: $magenta; }
    .metric-data .metric-scale trough highlight {
      background-image: linear-gradient(to right, $magenta, $blue);
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
      text-transform: uppercase;
      letter-spacing: 1px;
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
      background-image: linear-gradient(to right, $magenta, $blue);
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
      line-height: 1.6;
    }

    // ── News ──
    .news-card {
      border-left: 3px solid $orange;
    }

    .news-text {
      font-size: 12px;
      line-height: 1.7;
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
