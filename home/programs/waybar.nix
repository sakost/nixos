# Waybar — status bar for Hyprland
{ theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = [{
      layer = "top";
      position = "top";
      height = 34;
      spacing = 8;

      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [
        "hyprland/language"
        "pulseaudio"
        "network"
        "cpu"
        "memory"
        "tray"
      ];

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

      clock = {
        format = " {:%H:%M}";
        format-alt = " {:%A, %d %B %Y   %H:%M:%S}";
        on-click = "eww-toggle-calendar";
        tooltip = false;
        locale = "ru_RU.UTF-8";
        calendar = {
          mode = "month";
          mode-mon-col = 1;
          weeks-pos = "right";
          on-scroll = 1;
          format = {
            months = "<span color='${c.fg}' size='x-large'><b>{}</b></span>";
            days = "<span color='${c.fg-dim}'>{}</span>";
            weekdays = "<span color='${c.accent}'><b>{}</b></span>";
            weeks = "<span color='${c.muted}'>W{}</span>";
            today = "<span color='${c.bg}' bgcolor='${c.bright-green}'><b> {} </b></span>";
          };
        };
        actions = {
          on-click-right = "mode";
          on-scroll-up = "shift_up";
          on-scroll-down = "shift_down";
        };
        interval = 1;
      };

      "hyprland/language" = {
        format = "{}";
        format-en = "EN";
        format-ru = "RU";
      };

      pulseaudio = {
        format = "{volume}% {icon}";
        format-muted = "muted ";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      network = {
        format-wifi = "{essid} ({signalStrength}%)";
        format-ethernet = "{ipaddr}/{cidr}";
        format-disconnected = "disconnected";
        tooltip-format = "{ifname}: {ipaddr}/{cidr} via {gwaddr}";
      };

      cpu = {
        format = "{usage}% CPU";
        interval = 5;
      };

      memory = {
        format = "{percentage}% MEM";
        interval = 5;
      };

      tray = {
        spacing = 10;
      };
    }];

    style = ''
      * {
        font-family: "${theme.fonts.mono}", "Noto Sans", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: ${rgba c.bg theme.opacity.panel};
        color: ${c.fg};
        border-bottom: ${toString theme.border.width}px solid ${rgba c.bright-cyan 0.5};
      }

      tooltip {
        background-color: ${c.bg};
        border: 1px solid ${rgba c.bright-cyan 0.6};
        border-radius: ${toString theme.border.radius.medium}px;
        color: ${c.fg};
        padding: 12px 16px;
        font-size: ${toString theme.fonts.size.medium}px;
      }

      tooltip label {
        font-family: "${theme.fonts.mono}", monospace;
        min-width: 280px;
      }

      #workspaces button {
        padding: 0 8px;
        color: ${c.muted};
        border-bottom: ${toString theme.border.width}px solid transparent;
        border-radius: 0;
        background: transparent;
      }

      #workspaces button.active {
        color: ${c.bright-cyan};
        border-bottom: ${toString theme.border.width}px solid ${c.bright-cyan};
      }

      #workspaces button:hover {
        background: ${rgba c.bright-cyan 0.15};
        color: ${c.fg};
      }

      #window {
        padding: 0 12px;
        color: ${c.window-fg};
      }

      #clock {
        padding: 0 12px;
        color: ${c.fg};
        font-weight: bold;
      }

      #language,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #tray {
        padding: 0 10px;
        color: ${c.fg};
      }

      #language {
        color: ${c.bright-green};
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
    '';
  };
}
