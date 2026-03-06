# Waybar — glassmorphic pill-based status bar for Hyprland
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
      height = 40;
      spacing = 0;
      margin-top = 4;
      margin-left = 6;
      margin-right = 6;

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
        on-click-right = "env GTK_THEME=Adwaita:dark gsimplecal";
        tooltip = false;
        locale = "ru_RU.UTF-8";
        interval = 1;
      };

      "hyprland/language" = {
        format = "{}";
        format-en = "EN";
        format-ru = "RU";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = " muted";
        format-icons = {
          default = [ "" "" "" ];
        };
        on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };

      network = {
        format-wifi = " {essid}";
        format-ethernet = " {ipaddr}";
        format-disconnected = " disconnected";
        tooltip-format = "{ifname}: {ipaddr}/{cidr} via {gwaddr}";
      };

      cpu = {
        format = " {usage}%";
        interval = 5;
      };

      memory = {
        format = " {percentage}%";
        interval = 5;
      };

      tray = {
        spacing = 8;
      };
    }];

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
