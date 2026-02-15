# Eww dashboard overlay for HDMI-A-1
# Shows clock, weather (wttr.in), and Hacker News headlines
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

    # WMO weather code to icon
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

    echo "Moscow"
    echo "$ICON $DESC, ''${TEMP}°C"
    echo "Feels like ''${FEELS}°C"
    echo "Humidity: ''${HUMIDITY}%"
    echo "Wind: ''${WIND} km/h"
  '';

  news-script = pkgs.writeShellScriptBin "eww-news" ''
    ${pkgs.curl}/bin/curl -s 'https://hn.algolia.com/api/v1/search?tags=front_page&hitsPerPage=7' \
      | ${pkgs.jq}/bin/jq -r '.hits[] | "\(.title)"' 2>/dev/null || echo "News unavailable"
  '';
in
{
  home.packages = [ pkgs.eww weather-script news-script ];

  xdg.configFile."eww/eww.yuck".text = ''
    ;; ── Polled variables ──
    (defpoll time_val :interval "1s" :initial "00:00" `date '+%H:%M'`)
    (defpoll date_val :interval "60s" :initial "" `date '+%A, %B %d'`)
    (defpoll weather_val :interval "1800s" :initial "Loading..." `${weather-script}/bin/eww-weather`)
    (defpoll news_val :interval "600s" :initial "Loading..." `${news-script}/bin/eww-news`)

    ;; ── Widgets ──
    (defwidget dashboard []
      (box :class "dashboard" :orientation "v" :space-evenly false :halign "center" :valign "center"
        (clock-widget)
        (weather-widget)
        (news-widget)))

    (defwidget clock-widget []
      (box :class "widget-box clock-box" :orientation "v" :space-evenly false
        (label :class "time" :text time_val)
        (label :class "date" :text date_val)))

    (defwidget weather-widget []
      (box :class "widget-box" :orientation "v" :space-evenly false
        (label :class "section-title" :text "Weather")
        (label :class "content" :text weather_val :wrap true)))

    (defwidget news-widget []
      (box :class "widget-box" :orientation "v" :space-evenly false
        (label :class "section-title" :text "Hacker News")
        (label :class "content news-text" :text news_val :wrap true)))

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
    $fg: rgba(192, 202, 245, 0.95);
    $accent: rgba(122, 162, 247, 0.95);
    $border: rgba(122, 162, 247, 0.2);

    * {
      all: unset;
      font-family: "JetBrainsMono Nerd Font", monospace;
    }

    .dashboard {
      padding: 60px;
    }

    .widget-box {
      background-color: $bg;
      border-radius: 16px;
      padding: 24px 32px;
      margin-bottom: 20px;
      border: 1px solid $border;
      min-width: 420px;
    }

    .clock-box {
      padding: 40px 32px;

      .time {
        font-size: 64px;
        font-weight: bold;
        color: $fg;
        margin-bottom: 8px;
      }

      .date {
        font-size: 22px;
        color: $accent;
      }
    }

    .section-title {
      font-size: 18px;
      font-weight: bold;
      color: $accent;
      margin-bottom: 12px;
    }

    .content {
      font-size: 14px;
      color: $fg;
      padding: 4px 0;
    }

    .news-text {
      font-size: 13px;
      padding: 6px 0;
    }
  '';
}
