# Eww dashboard overlay for HDMI-A-1
# Info hub: clock, weather, system stats, media player, calendar, news, notification status
{ pkgs, ... }:

let
  weather-script = pkgs.writeShellScriptBin "eww-weather" ''
    DATA=$(${pkgs.curl}/bin/curl -s --max-time 10 \
      'https://api.open-meteo.com/v1/forecast?latitude=55.75&longitude=37.62&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m&timezone=Europe/Moscow' 2>/dev/null)
    [[ -z "$DATA" ]] && echo "Weather unavailable" && exit 0

    TEMP=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.temperature_2m')
    FEELS=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.apparent_temperature')
    HUMIDITY=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.relative_humidity_2m')
    WIND=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.wind_speed_10m')
    CODE=$(echo "$DATA" | ${pkgs.jq}/bin/jq -r '.current.weather_code')

    case "$CODE" in
      0) ICON="☀" DESC="Clear sky" ;;
      1|2|3) ICON="⛅" DESC="Partly cloudy" ;;
      45|48) ICON="🌫" DESC="Fog" ;;
      51|53|55) ICON="🌦" DESC="Drizzle" ;;
      61|63|65) ICON="🌧" DESC="Rain" ;;
      66|67) ICON="🌧" DESC="Freezing rain" ;;
      71|73|75) ICON="🌨" DESC="Snow" ;;
      77) ICON="🌨" DESC="Snow grains" ;;
      80|81|82) ICON="🌧" DESC="Showers" ;;
      85|86) ICON="🌨" DESC="Snow showers" ;;
      95|96|99) ICON="⛈" DESC="Thunderstorm" ;;
      *) ICON="?" DESC="Unknown" ;;
    esac

    echo "Moscow · $ICON $DESC"
    echo "''${TEMP}°C (feels ''${FEELS}°C)"
    echo "💧 ''${HUMIDITY}%  ·  💨 ''${WIND} km/h"
  '';

  sysinfo-script = pkgs.writeShellScriptBin "eww-sysinfo" ''
    net_bytes() {
      ${pkgs.gawk}/bin/awk '/:/ && !/lo:/ {rx+=$2; tx+=$10} END{print rx, tx}' /proc/net/dev
    }

    # Snapshot 1 (CPU + network)
    read -ra CPU1 <<< "$(head -1 /proc/stat)"
    read -r NET_RX1 NET_TX1 <<< "$(net_bytes)"
    NET_RX1=''${NET_RX1:-0}; NET_TX1=''${NET_TX1:-0}

    sleep 1

    # Snapshot 2
    read -ra CPU2 <<< "$(head -1 /proc/stat)"
    read -r NET_RX2 NET_TX2 <<< "$(net_bytes)"
    NET_RX2=''${NET_RX2:-0}; NET_TX2=''${NET_TX2:-0}

    # CPU%
    idle1=''${CPU1[4]}; total1=0
    for v in "''${CPU1[@]:1}"; do total1=$((total1 + v)); done
    idle2=''${CPU2[4]}; total2=0
    for v in "''${CPU2[@]:1}"; do total2=$((total2 + v)); done
    dt=$((total2 - total1)); di=$((idle2 - idle1))
    cpu=0; ((dt > 0)) && cpu=$(( (dt - di) * 100 / dt ))

    # RAM
    total_kb=$(${pkgs.gawk}/bin/awk '/^MemTotal:/{print $2}' /proc/meminfo)
    avail_kb=$(${pkgs.gawk}/bin/awk '/^MemAvailable:/{print $2}' /proc/meminfo)
    used_kb=$((total_kb - avail_kb))
    ram=$((used_kb * 100 / total_kb))
    ram_used=$(${pkgs.gawk}/bin/awk "BEGIN{printf \"%.1f\", $used_kb / 1048576}")
    ram_total=$(${pkgs.gawk}/bin/awk "BEGIN{printf \"%.1f\", $total_kb / 1048576}")

    # Disks
    sys_info=$(df -h / | tail -1)
    sys_total_h=$(echo "$sys_info" | ${pkgs.gawk}/bin/awk '{print $2}')
    sys_used_h=$(echo "$sys_info" | ${pkgs.gawk}/bin/awk '{print $3}')
    sys=$(echo "$sys_info" | ${pkgs.gawk}/bin/awk '{gsub(/%/,""); print $5}')

    data_info=$(df -h /home/sakost/dev | tail -1)
    data_total_h=$(echo "$data_info" | ${pkgs.gawk}/bin/awk '{print $2}')
    data_used_h=$(echo "$data_info" | ${pkgs.gawk}/bin/awk '{print $3}')
    data=$(echo "$data_info" | ${pkgs.gawk}/bin/awk '{gsub(/%/,""); print $5}')

    # GPU temp
    gpu=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null || echo "N/A")

    # Network speed
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
      echo '{"status":"Stopped","icon":"⏹","title":"","detail":"","position":"0:00","length":"0:00","pct":0}'
      exit 0
    fi

    TITLE=$(${pkgs.playerctl}/bin/playerctl metadata title 2>/dev/null || echo "")
    ARTIST=$(${pkgs.playerctl}/bin/playerctl metadata artist 2>/dev/null || echo "")
    ALBUM=$(${pkgs.playerctl}/bin/playerctl metadata album 2>/dev/null || echo "")
    POS_RAW=$(${pkgs.playerctl}/bin/playerctl position 2>/dev/null || echo "0")
    LEN_US=$(${pkgs.playerctl}/bin/playerctl metadata mpris:length 2>/dev/null || echo "0")
    [[ -z "$POS_RAW" ]] && POS_RAW="0"
    [[ -z "$LEN_US" ]] && LEN_US="0"

    pos_sec=''${POS_RAW%.*}
    len_sec=$((LEN_US / 1000000))
    pos_m=$((pos_sec / 60)); pos_s=$((pos_sec % 60))
    len_m=$((len_sec / 60)); len_s=$((len_sec % 60))
    pct=0; ((len_sec > 0)) && pct=$((pos_sec * 100 / len_sec))

    ICON="▶"; [[ "$STATUS" == "Paused" ]] && ICON="⏸"
    POS_FMT=$(printf '%d:%02d' $pos_m $pos_s)
    LEN_FMT=$(printf '%d:%02d' $len_m $len_s)

    if [[ -n "$ALBUM" ]]; then DETAIL="$ARTIST · $ALBUM"; else DETAIL="$ARTIST"; fi

    ${pkgs.jq}/bin/jq -nc \
      --arg status "$STATUS" --arg icon "$ICON" --arg title "$TITLE" \
      --arg detail "$DETAIL" --arg position "$POS_FMT" --arg length "$LEN_FMT" \
      --argjson pct "$pct" \
      '{status:$status, icon:$icon, title:$title, detail:$detail, position:$position, length:$length, pct:$pct}'
  '';

  calendar-script = pkgs.writeShellScriptBin "eww-calendar" ''
    # Strip ANSI escape codes — gcalcli's --nocolor doesn't fully strip them
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
    echo "DND: $DND  ·  Work: $WORK"
  '';

  news-script = pkgs.writeShellScriptBin "eww-news" ''
    ${pkgs.curl}/bin/curl -s 'https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=7' \
      | ${pkgs.jq}/bin/jq -r '.hits[] | "\(.title)"' 2>/dev/null || echo "News unavailable"
  '';
in
{
  home.packages = [
    pkgs.eww
    pkgs.gcalcli
    weather-script
    news-script
    sysinfo-script
    player-script
    calendar-script
    mako-status-script
  ];

  xdg.configFile."eww/eww.yuck".text = ''
    ;; ── Polled variables ──
    (defpoll time_val :interval "1s" :initial "00:00" `date '+%H:%M'`)
    (defpoll date_val :interval "60s" :initial "" `date '+%A, %B %d'`)
    (defpoll weather_val :interval "1800s" :initial "Loading..." `${weather-script}/bin/eww-weather`)
    (defpoll sysinfo :interval "3s"
      :initial '{"cpu":0,"ram":0,"ram_used":"0","ram_total":"0","sys":0,"sys_used":"--","sys_total":"--","data":0,"data_used":"--","data_total":"--","gpu":"--","net_up":"--","net_down":"--"}'
      `${sysinfo-script}/bin/eww-sysinfo`)
    (defpoll player :interval "2s"
      :initial '{"status":"Stopped","icon":"⏹","title":"","detail":"","position":"0:00","length":"0:00","pct":0}'
      `${player-script}/bin/eww-player`)
    (defpoll calendar_val :interval "300s" :initial "Loading..." `${calendar-script}/bin/eww-calendar`)
    (defpoll news_val :interval "600s" :initial "Loading..." `${news-script}/bin/eww-news`)
    (defpoll mako_val :interval "5s" :initial "DND: off  ·  Work: off" `${mako-status-script}/bin/eww-mako-status`)

    ;; ── Reusable metric bar (label + progress + detail text) ──
    (defwidget metric [label value text]
      (box :class "metric" :orientation "h" :space-evenly false
        (label :class "metric-label" :text label)
        (scale :class "metric-scale" :min 0 :max 100 :value value :active false :orientation "h" :hexpand true)
        (label :class "metric-text" :text text)))

    ;; ── Dashboard ──
    (defwidget dashboard []
      (box :class "dashboard" :orientation "v" :space-evenly false :halign "center" :valign "center"
        (clock-widget)
        (box :class "two-col" :orientation "h" :space-evenly true
          (weather-widget)
          (sysinfo-widget))
        (player-widget)
        (calendar-widget)
        (news-widget)
        (mako-widget)))

    (defwidget clock-widget []
      (box :class "widget-box clock-box" :orientation "v" :space-evenly false
        (label :class "time" :text time_val :halign "center")
        (label :class "date" :text date_val :halign "center")))

    (defwidget weather-widget []
      (box :class "widget-box" :orientation "v" :space-evenly false
        (label :class "section-title" :text "Weather")
        (label :class "content" :text weather_val :wrap true)))

    (defwidget sysinfo-widget []
      (box :class "widget-box" :orientation "v" :space-evenly false
        (label :class "section-title" :text "System")
        (metric :label "CPU" :value {sysinfo.cpu} :text "''${sysinfo.cpu}%")
        (metric :label "RAM" :value {sysinfo.ram} :text "''${sysinfo.ram_used}G / ''${sysinfo.ram_total}G")
        (metric :label "SYS" :value {sysinfo.sys} :text "''${sysinfo.sys_used} / ''${sysinfo.sys_total}")
        (metric :label "DATA" :value {sysinfo.data} :text "''${sysinfo.data_used} / ''${sysinfo.data_total}")
        (box :class "stat-text-row" :orientation "h" :space-evenly false
          (label :class "stat-icon" :text " ")
          (label :class "stat-detail" :text "''${sysinfo.gpu}°C")
          (label :class "stat-spacer" :text "   ")
          (label :class "stat-icon" :text " ")
          (label :class "stat-detail" :text "↑''${sysinfo.net_up}  ↓''${sysinfo.net_down}"))))

    (defwidget player-widget []
      (box :class "widget-box player-box" :orientation "v" :space-evenly false
        :visible {player.status != "Stopped"}
        (box :orientation "h" :space-evenly false
          (label :class "player-icon" :text {player.icon})
          (box :orientation "v" :space-evenly false :hexpand true
            (label :class "player-title" :text {player.title} :halign "start")
            (label :class "player-detail" :text {player.detail} :halign "start")))
        (box :class "player-progress-row" :orientation "h" :space-evenly false
          (label :class "player-time" :text {player.position})
          (scale :class "player-scale" :min 0 :max 100 :value {player.pct} :active false :orientation "h" :hexpand true)
          (label :class "player-time" :text {player.length}))))

    (defwidget calendar-widget []
      (box :class "widget-box" :orientation "v" :space-evenly false
        (label :class "section-title" :text "Calendar")
        (label :class "content calendar-text" :text calendar_val :wrap true)))

    (defwidget news-widget []
      (box :class "widget-box" :orientation "v" :space-evenly false
        (label :class "section-title" :text "Hacker News")
        (label :class "content news-text" :text news_val :wrap true)))

    (defwidget mako-widget []
      (box :class "mako-status" :orientation "h" :space-evenly false :halign "center"
        (label :text mako_val)))

    ;; ── Window on HDMI-A-1, bottom layer (above wallpaper, below windows) ──
    (defwindow dashboard
      :monitor "HDMI-A-1"
      :geometry (geometry :x "0%" :y "0%" :width "100%" :height "100%")
      :stacking "bottom"
      :exclusive false
      :focusable false
      (dashboard))
  '';

  xdg.configFile."eww/eww.scss".text = ''
    // TokyoNight-inspired palette
    $bg: rgba(26, 27, 38, 0.6);
    $bg-dark: rgba(16, 17, 28, 0.7);
    $fg: rgba(192, 202, 245, 0.95);
    $fg-dim: rgba(169, 177, 214, 0.7);
    $accent: rgba(122, 162, 247, 0.95);
    $green: rgba(158, 206, 106, 0.95);
    $border: rgba(122, 162, 247, 0.2);

    * {
      all: unset;
      font-family: "JetBrainsMono Nerd Font", monospace;
    }

    .dashboard {
      padding: 40px;
    }

    .widget-box {
      background-color: $bg;
      border-radius: 16px;
      padding: 20px 24px;
      margin-bottom: 16px;
      border: 1px solid $border;
    }

    // ── Clock ──
    .clock-box {
      padding: 32px 24px;

      .time {
        font-size: 56px;
        font-weight: bold;
        color: $fg;
      }

      .date {
        font-size: 20px;
        color: $accent;
        margin-top: 8px;
      }
    }

    // ── Two-column row ──
    .two-col {
      margin-bottom: 16px;
    }

    .two-col > * {
      margin: 0;
      margin-bottom: 0;
    }

    // ── Section titles ──
    .section-title {
      font-size: 15px;
      font-weight: bold;
      color: $accent;
      margin-bottom: 10px;
    }

    .content {
      font-size: 13px;
      color: $fg;
      padding: 2px 0;
    }

    // ── System metrics ──
    .metric {
      margin: 3px 0;
    }

    .metric-label {
      font-size: 11px;
      color: $fg-dim;
      min-width: 40px;
      margin-right: 8px;
    }

    .metric-text {
      font-size: 11px;
      color: $fg-dim;
      min-width: 110px;
      margin-left: 8px;
    }

    .metric-scale trough {
      background-color: $bg-dark;
      border-radius: 3px;
      min-height: 6px;
    }

    .metric-scale trough highlight {
      background-image: linear-gradient(to right, $accent, $green);
      border-radius: 3px;
      min-height: 6px;
    }

    .metric-scale slider {
      margin: 0;
      padding: 0;
      min-width: 0;
      min-height: 0;
      background-color: transparent;
    }

    .stat-text-row {
      margin-top: 6px;
    }

    .stat-icon {
      font-size: 13px;
      color: $accent;
      margin-right: 4px;
    }

    .stat-detail {
      font-size: 11px;
      color: $fg-dim;
      margin-right: 12px;
    }

    .stat-spacer {
      min-width: 8px;
    }

    // ── Media player ──
    .player-box {
      border-left: 3px solid $accent;
    }

    .player-icon {
      font-size: 22px;
      color: $accent;
      margin-right: 14px;
      margin-top: 2px;
    }

    .player-title {
      font-size: 14px;
      font-weight: bold;
      color: $fg;
    }

    .player-detail {
      font-size: 12px;
      color: $fg-dim;
      margin-top: 2px;
    }

    .player-progress-row {
      margin-top: 8px;
    }

    .player-time {
      font-size: 10px;
      color: $fg-dim;
      min-width: 36px;
    }

    .player-scale {
      margin: 0 8px;
    }

    .player-scale trough {
      background-color: $bg-dark;
      border-radius: 2px;
      min-height: 4px;
    }

    .player-scale trough highlight {
      background-color: $accent;
      border-radius: 2px;
      min-height: 4px;
    }

    .player-scale slider {
      margin: 0;
      padding: 0;
      min-width: 0;
      min-height: 0;
      background-color: transparent;
    }

    // ── Calendar ──
    .calendar-text {
      font-size: 13px;
    }

    // ── News ──
    .news-text {
      font-size: 12px;
      padding: 4px 0;
    }

    // ── Mako status footer ──
    .mako-status {
      font-size: 12px;
      color: $fg-dim;
      padding: 4px 0;
    }
  '';
}
