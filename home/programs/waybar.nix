# Waybar — glassmorphic pill-based status bar for Hyprland
{ theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;

  # Nerd Font icon helpers — produce actual Unicode chars from hex codepoints
  # BMP icons (U+0000–U+FFFF): 4 hex digits
  nfIcon = hex: (builtins.fromJSON ("\"\\u" + hex + "\""));
  # SMP icons (U+10000+): JSON surrogate pair from high+low hex strings
  nfIconSMP = high: low: (builtins.fromJSON ("\"\\u" + high + "\\u" + low + "\""));

  icons = {
    clock     = nfIcon "f017";                 # nf-fa-clock_o
    calendar  = nfIcon "f073";                 # nf-fa-calendar
    music     = nfIcon "f001";                 # nf-fa-music
    pause     = nfIcon "f04c";                 # nf-fa-pause
    vol-low   = nfIconSMP "DB81" "DD7F";       # nf-md-volume_low      U+F057F
    vol-med   = nfIconSMP "DB81" "DD80";       # nf-md-volume_medium   U+F0580
    vol-high  = nfIconSMP "DB81" "DD7E";       # nf-md-volume_high     U+F057E
    vol-mute  = nfIconSMP "DB81" "DF5F";       # nf-md-volume_mute     U+F075F
    wifi      = nfIcon "f1eb";                 # nf-fa-wifi
    ethernet  = nfIconSMP "DB80" "DE00";       # nf-md-ethernet        U+F0200
    no-net    = nfIcon "f127";                 # nf-fa-unlink
    cpu       = nfIcon "f2db";                 # nf-fa-microchip
    memory    = nfIconSMP "DB80" "DF5B";       # nf-md-memory          U+F035B
  };
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings =
    let
      # Shared module configs reused across both bars
      commonModules = {
        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
          sort-by-number = true;
          separate-outputs = true;
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
        };

        "hyprland/language" = {
          format = "{}";
          format-en = "EN";
          format-ru = "RU";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "${icons.vol-mute} muted";
          format-icons = {
            default = [ "${icons.vol-low}" "${icons.vol-med}" "${icons.vol-high}" ];
          };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };

        network = {
          format-wifi = "${icons.wifi} {essid}";
          format-ethernet = "${icons.ethernet} {ipaddr}";
          format-disconnected = "${icons.no-net} disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr} via {gwaddr}";
        };

        cpu = {
          format = "${icons.cpu} {usage}%";
          interval = 5;
        };

        memory = {
          format = "${icons.memory} {percentage}%";
          interval = 5;
        };

        tray = {
          spacing = 8;
        };

        "custom/media" = {
          format = "{}";
          return-type = "json";
          max-length = 40;
          exec = "playerctl -F metadata --format '{\"text\": \"${icons.music} {{artist}} — {{title}}\", \"tooltip\": \"{{playerName}}: {{artist}} — {{title}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' 2>/dev/null";
          on-click = "playerctl play-pause";
          on-scroll-up = "playerctl next";
          on-scroll-down = "playerctl previous";
        };
      };

      commonBar = {
        layer = "top";
        position = "top";
        height = 40;
        spacing = 0;
        margin-top = 4;
        margin-left = 6;
        margin-right = 6;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" "custom/media" ];
        modules-right = [
          "hyprland/language"
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "tray"
        ];
      };
    in [
      # Primary monitor (DP-2) — time only, calendar on left-click
      (commonBar // commonModules // {
        output = "DP-2";
        clock = {
          format = "${icons.clock} {:%H:%M}";
          on-click = "env GTK_THEME=Adwaita:dark gsimplecal";
          tooltip = false;
          locale = "ru_RU.UTF-8";
          interval = 1;
        };
      })

      # Secondary monitor (HDMI-A-1) — full datetime, calendar on left-click
      (commonBar // commonModules // {
        output = "HDMI-A-1";
        clock = {
          format = "${icons.calendar} {:%A, %d %B %Y   %H:%M:%S}";
          on-click = "env GTK_THEME=Adwaita:dark gsimplecal";
          tooltip = false;
          locale = "ru_RU.UTF-8";
          interval = 1;
        };
      })
    ];

    style = ''
      /* ── Reset & base typography ── */
      * {
        font-family: "${theme.fonts.mono}", "Noto Sans", sans-serif;
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
      }

      /* ── Bar: fully transparent, floating via margins ── */
      window#waybar {
        background: transparent;
        color: ${c.fg};
      }

      /* ── Tooltip ── */
      tooltip {
        background-color: ${rgba c.bg 0.92};
        border: 1px solid ${rgba c.white 0.08};
        border-radius: ${toString theme.border.radius.medium}px;
        color: ${c.fg};
        padding: 10px 14px;
        font-size: ${toString theme.fonts.size.medium}px;
      }

      tooltip label {
        font-family: "${theme.fonts.mono}", monospace;
        min-width: 260px;
      }

      /* ── Glassmorphic pill base ── */
      #workspaces,
      #window,
      #clock,
      #custom-media,
      #language,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #tray {
        background: ${rgba c.bg 0.85};
        border: 1px solid ${rgba c.white 0.06};
        border-radius: ${toString theme.border.radius.medium}px;
        padding: 2px 12px;
        margin: 4px 3px;
        color: ${c.fg};
      }

      /* ── Workspaces pill ── */
      #workspaces {
        padding: 2px 4px;
      }

      #workspaces button {
        padding: 2px 8px;
        margin: 2px 2px;
        border-radius: ${toString theme.border.radius.small}px;
        color: ${c.muted};
        background: transparent;
        transition: all 0.2s ease;
      }

      #workspaces button.empty {
        color: ${c.bright-black};
      }

      #workspaces button.active {
        background: ${c.accent};
        color: ${c.bg-dark};
        font-weight: bold;
      }

      #workspaces button:hover {
        background: ${rgba c.accent 0.2};
        color: ${c.fg};
      }

      /* ── Window title ── */
      #window {
        color: ${c.fg-dim};
        font-style: italic;
      }

      /* Empty window — hide the pill when no title */
      window#waybar.empty #window {
        background: transparent;
        border-color: transparent;
        padding: 0;
        margin: 0;
      }

      /* ── Clock pill ── */
      #clock {
        font-size: ${toString theme.fonts.size.medium}px;
        font-weight: bold;
        color: ${c.accent};
        padding: 2px 18px;
      }

      /* ── Media pill ── */
      #custom-media {
        color: ${c.magenta};
        font-style: italic;
      }

      #custom-media.Paused {
        color: ${c.muted};
      }

      /* ── Right-side module pills with individual accent colors ── */
      #language {
        color: ${c.teal};
        font-weight: bold;
      }

      #pulseaudio {
        color: ${c.blue};
      }

      #pulseaudio.muted {
        color: ${c.muted};
      }

      #network {
        color: ${c.green};
      }

      #network.disconnected {
        color: ${c.red};
      }

      #cpu {
        color: ${c.yellow};
      }

      #memory {
        color: ${c.magenta};
      }

      #tray {
        padding: 2px 8px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
      }

      /* ── Hover effects: subtle brightness increase ── */
      #workspaces button:hover,
      #window:hover,
      #clock:hover,
      #custom-media:hover,
      #language:hover,
      #pulseaudio:hover,
      #network:hover,
      #cpu:hover,
      #memory:hover,
      #tray:hover {
        background: ${rgba c.bg-light 0.95};
        border-color: ${rgba c.white 0.1};
      }

      /* Keep active workspace highlight on hover */
      #workspaces button.active:hover {
        background: ${c.accent};
        color: ${c.bg-dark};
      }
    '';
  };
}
