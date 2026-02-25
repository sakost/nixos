# Lock screen (hyprlock)
{ config, pkgs, ... }:

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
          color = "rgb(1a1b26)";
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
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgb(7aa2f7)";
          inner_color = "rgb(1a1b26)";
          font_color = "rgb(c0caf5)";
          fade_on_empty = true;
          fade_timeout = 2000;
          placeholder_text = "<span foreground=\"##565f89\">Password...</span>";
          fail_color = "rgb(f7768e)";
          fail_text = "<i>$FAIL <b>($ATTEMPTS)</b></i>";
          fail_transition = 300;
          check_color = "rgb(e0af68)";
          capslock_color = "rgb(e0af68)";
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
          color = "rgb(c0caf5)";
          font_size = 72;
          font_family = "JetBrainsMono Nerd Font";
          halign = "center";
          valign = "center";
          position = "0, 150";
        }
        # Date
        {
          monitor = "";
          text = "cmd[update:3600000] date +\"%A, %d %B\"";
          color = "rgb(565f89)";
          font_size = 18;
          font_family = "JetBrainsMono Nerd Font";
          halign = "center";
          valign = "center";
          position = "0, 75";
        }
      ];
    };
  };
}
