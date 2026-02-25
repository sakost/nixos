# Alacritty terminal configuration
{ theme, ... }:

let
  c = theme.colors;
in
{
  programs.alacritty = {
    enable = true;

    settings = {
      env = {
        TERM = "xterm-256color";
      };

      scrolling = {
        history = 50000;
      };

      window = {
        opacity = theme.opacity.terminal;
        padding = {
          x = 10;
          y = 10;
        };
      };

      font = {
        size = theme.fonts.size.normal * 1.0;
        normal = {
          family = theme.fonts.mono;
          style = "Regular";
        };
      };

      colors = {
        primary = {
          background = c.bg;
          foreground = c.fg;
        };

        normal = {
          black   = c.bg-dark;
          red     = c.red;
          green   = c.green;
          yellow  = c.yellow;
          blue    = c.blue;
          magenta = c.magenta;
          cyan    = c.cyan;
          white   = c.fg-dim;
        };

        bright = {
          black   = c.bright-black;
          red     = c.red;
          green   = c.green;
          yellow  = c.yellow;
          blue    = c.blue;
          magenta = c.magenta;
          cyan    = c.cyan;
          white   = c.fg;
        };

        selection = {
          background = c.selection;
          foreground = c.fg;
        };
      };
    };
  };
}
