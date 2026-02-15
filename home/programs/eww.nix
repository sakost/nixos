# Eww dashboard overlay for HDMI-A-1
# Shows clock, weather (wttr.in), and Hacker News headlines
{ pkgs, ... }:

let
  weather-script = pkgs.writeShellScriptBin "eww-weather" ''
    ${pkgs.curl}/bin/curl -s 'wttr.in/?format=%l\n%c+%C,+%t\nFeels+like+%f\nHumidity:+%h\nWind:+%w' 2>/dev/null || echo "Weather unavailable"
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
      line-height: 1.6;
    }

    .news-text {
      font-size: 13px;
      line-height: 1.8;
    }
  '';
}
