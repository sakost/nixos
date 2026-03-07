# Lock screen (hyprlock)
{ theme, pkgs, ... }:

let
  c = theme.colors;
  # hyprlock uses rgb() without the # prefix
  rgb = color: "rgb(${builtins.substring 1 6 color})";

  # Nerd Font SMP icon helper — produce actual Unicode char from surrogate pair
  nfIconSMP = high: low: (builtins.fromJSON ("\"\\u" + high + "\\u" + low + "\""));

  # Script: get current keyboard layout
  hyprlock-layout = pkgs.writeShellScriptBin "hyprlock-layout" ''
    LAYOUT=$(hyprctl devices -j | ${pkgs.jq}/bin/jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n 1)
    case "$LAYOUT" in
      *"English (US)"*) echo "US" ;;
      *"Russian"*)      echo "RU" ;;
      *)                echo "''${LAYOUT:0:3}" ;;
    esac
  '';

  # Script: get battery/AC status (desktop shows AC icon, laptop shows battery)
  hyprlock-power = pkgs.writeShellScriptBin "hyprlock-power" ''
    if [ -d /sys/class/power_supply/BAT0 ]; then
      BATTERY_DIR="/sys/class/power_supply/BAT0"
    elif [ -d /sys/class/power_supply/BAT1 ]; then
      BATTERY_DIR="/sys/class/power_supply/BAT1"
    else
      # Desktop — show AC power icon
      printf '\U000f06a5 AC'
      exit 0
    fi

    STATUS=$(cat "$BATTERY_DIR/status")
    CAPACITY=$(cat "$BATTERY_DIR/capacity")

    if [ "$STATUS" = "Charging" ]; then
      ICON=$(printf '\U000f0084')
    elif [ "$CAPACITY" -ge 80 ]; then
      ICON=$(printf '\U000f0079')
    elif [ "$CAPACITY" -ge 60 ]; then
      ICON=$(printf '\U000f0078')
    elif [ "$CAPACITY" -ge 40 ]; then
      ICON=$(printf '\U000f0077')
    elif [ "$CAPACITY" -ge 20 ]; then
      ICON=$(printf '\U000f0076')
    else
      ICON=$(printf '\U000f0075')
    fi

    echo "$ICON $CAPACITY%"
  '';
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        grace = 3;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          path = "screenshot";
          color = "rgba(26, 27, 38, 0.85)";
          blur_passes = 4;
          blur_size = 8;
          noise = 1.17e-2;
          contrast = 0.9;
          brightness = 0.55;
          vibrancy = 0.17;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "220, 40";
          rounding = -1;
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = rgb c.magenta;
          inner_color = rgb c.surface0;
          font_color = rgb c.fg;
          fade_on_empty = true;
          fade_timeout = 2000;
          placeholder_text = "<i>Password...</i>";
          fail_color = rgb c.error;
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          fail_transition = 300;
          check_color = rgb c.green;
          capslock_color = rgb c.orange;
          halign = "center";
          valign = "center";
          position = "0, -80";
        }
      ];

      shape = [
        # Bottom dock
        {
          monitor = "";
          size = "500, 50";
          color = "rgba(21, 22, 30, 0.6)";
          rounding = -1;
          border_size = 1;
          border_color = "rgba(122, 162, 247, 0.3)";
          halign = "center";
          valign = "bottom";
          position = "0, 40";
          zindex = 1;
        }
      ];

      label = [
        # Time
        {
          monitor = "";
          text = "$TIME";
          color = rgb c.fg;
          font_size = 120;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "center";
          position = "0, 200";
        }
        # Date
        {
          monitor = "";
          text = "cmd[update:3600000] date +\"%A, %d %B\"";
          color = rgb c.fg-dim;
          font_size = 18;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "center";
          position = "0, 100";
        }
        # Username (left side of dock)
        {
          monitor = "";
          text = "  $USER";
          color = rgb c.magenta;
          font_size = 12;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "bottom";
          position = "-185, 53";
          zindex = 2;
        }
        # Keyboard layout + power status (right side of dock)
        {
          monitor = "";
          text = "cmd[update:1000] echo \"${nfIconSMP "DB80" "DD1C"}  $(${hyprlock-layout}/bin/hyprlock-layout)   |   $(${hyprlock-power}/bin/hyprlock-power)\"";
          color = rgb c.fg-dim;
          font_size = 12;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "bottom";
          position = "160, 53";
          zindex = 2;
        }
      ];
    };
  };
}
