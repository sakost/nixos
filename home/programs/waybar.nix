# Waybar — status bar for Hyprland
{ config, pkgs, ... }:

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
        format = "{icon}";
        tooltip-format = "{name}";
        on-click = "activate";
        sort-by-number = true;
        format-icons = {
          # Monitor 1 (workspaces 1-10)
          "1" = "1"; "2" = "2"; "3" = "3"; "4" = "4"; "5" = "5";
          "6" = "6"; "7" = "7"; "8" = "8"; "9" = "9"; "10" = "10";
          # Monitor 2 (workspaces 11-20, displayed as 1-10)
          "11" = "1"; "12" = "2"; "13" = "3"; "14" = "4"; "15" = "5";
          "16" = "6"; "17" = "7"; "18" = "8"; "19" = "9"; "20" = "10";
        };
      };

      "hyprland/window" = {
        max-length = 50;
        separate-outputs = true;
      };

      clock = {
        format = " {:%H:%M}";
        format-alt = " {:%A, %B %d, %Y   %H:%M:%S}";
        tooltip-format = "<tt><big>{calendar}</big></tt>";
        locale = "ru_RU.UTF-8";
        calendar = {
          mode = "month";
          weeks-pos = "right";
          format = {
            months = "<span color='#c0caf5'><b>{}</b></span>";
            days = "<span color='#565f89'>{}</span>";
            weekdays = "<span color='#7aa2f7'><b>{}</b></span>";
            weeks = "<span color='#33ccff'><b>W{}</b></span>";
            today = "<span color='#00ff99'><b><u>{}</u></b></span>";
          };
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
      /* TokyoNight-inspired dark theme */
      * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans", sans-serif;
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background-color: rgba(26, 27, 38, 0.85);
        color: #c0caf5;
        border-bottom: 2px solid rgba(51, 204, 255, 0.5);
      }

      tooltip {
        background-color: #1a1b26;
        border: 1px solid #33ccff;
        border-radius: 8px;
        color: #c0caf5;
      }

      #workspaces button {
        padding: 0 8px;
        color: #565f89;
        border-bottom: 2px solid transparent;
        border-radius: 0;
        background: transparent;
      }

      #workspaces button.active {
        color: #33ccff;
        border-bottom: 2px solid #33ccff;
      }

      #workspaces button:hover {
        background: rgba(51, 204, 255, 0.15);
        color: #c0caf5;
      }

      #window {
        padding: 0 12px;
        color: #9aa5ce;
      }

      #clock {
        padding: 0 12px;
        color: #c0caf5;
        font-weight: bold;
      }

      #language,
      #pulseaudio,
      #network,
      #cpu,
      #memory,
      #tray {
        padding: 0 10px;
        color: #c0caf5;
      }

      #language {
        color: #00ff99;
        font-weight: bold;
      }

      #pulseaudio {
        color: #7aa2f7;
      }

      #pulseaudio.muted {
        color: #565f89;
      }

      #network {
        color: #9ece6a;
      }

      #network.disconnected {
        color: #f7768e;
      }

      #cpu {
        color: #e0af68;
      }

      #memory {
        color: #bb9af7;
      }
    '';
  };
}
