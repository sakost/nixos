# Lock screen (hyprlock)
{ theme, ... }:

let
  c = theme.colors;
  # hyprlock uses rgb() without the # prefix
  rgb = color: "rgb(${builtins.substring 1 6 color})";
in
{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        grace = 3;
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
          placeholder_text = "<span foreground=\"#${builtins.substring 1 6 c.muted}\">Password...</span>";
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
        # Username (in dock)
        {
          monitor = "";
          text = "sakost";
          color = rgb c.magenta;
          font_size = 12;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "bottom";
          position = "-120, 53";
          zindex = 2;
        }
        # Keyboard layout hint (in dock)
        {
          monitor = "";
          text = "  EN / RU";
          color = rgb c.fg-dim;
          font_size = 12;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "bottom";
          position = "120, 53";
          zindex = 2;
        }
      ];
    };
  };
}
