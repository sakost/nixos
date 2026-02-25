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
          color = rgb c.bg;
          blur_passes = 3;
          blur_size = 8;
          noise = 1.17e-2;
          contrast = 0.9;
          brightness = 0.6;
          vibrancy = 0.17;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = theme.border.width;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = rgb c.accent;
          inner_color = rgb c.bg;
          font_color = rgb c.fg;
          fade_on_empty = true;
          fade_timeout = 2000;
          placeholder_text = "<span foreground=\"#${builtins.substring 1 6 c.muted}\">Password...</span>";
          fail_color = rgb c.error;
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          fail_transition = 300;
          check_color = rgb c.warn;
          capslock_color = rgb c.warn;
          halign = "center";
          valign = "center";
          position = "0, -50";
        }
      ];

      label = [
        # Time
        {
          monitor = "";
          text = "$TIME";
          color = rgb c.fg;
          font_size = 72;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "center";
          position = "0, 150";
        }
        # Date
        {
          monitor = "";
          text = "cmd[update:3600000] date +\"%A, %d %B\"";
          color = rgb c.muted;
          font_size = theme.fonts.size.large;
          font_family = theme.fonts.mono;
          halign = "center";
          valign = "center";
          position = "0, 75";
        }
      ];
    };
  };
}
