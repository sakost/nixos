# Centralized theme definition — imported via specialArgs as `theme`
# All color, font, opacity, and border values used across the desktop.
let
  # Convert "#rrggbb" to "r, g, b" decimal string for CSS rgba()
  hexToDec = c:
    let
      hexChars = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
        "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
        "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
        "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
      };
      h = builtins.substring;
      d = s: hexChars.${h 0 1 s} * 16 + hexChars.${h 1 1 s};
      hex = builtins.substring 1 6 c; # strip #
    in "${toString (d (h 0 2 hex))}, ${toString (d (h 2 2 hex))}, ${toString (d (h 4 2 hex))}";
in
{
  name = "tokyonight";

  # Convert hex color to CSS rgba: (theme.rgba c.accent 0.5) → "rgba(122, 162, 247, 0.5)"
  rgba = color: alpha: "rgba(${hexToDec color}, ${toString alpha})";

  colors = {
    # Base palette
    bg          = "#1a1b26";
    bg-dark     = "#15161e";
    bg-light    = "#24283b";
    fg          = "#c0caf5";
    fg-dim      = "#a9b1d6";
    fg-dark     = "#565f89";
    selection   = "#283457";

    red         = "#f7768e";
    green       = "#9ece6a";
    yellow      = "#e0af68";
    blue        = "#7aa2f7";
    magenta     = "#bb9af7";
    cyan        = "#7dcfff";
    teal        = "#73daca";
    bright-cyan = "#33ccff";
    bright-green = "#00ff99";
    bright-black = "#414868";
    window-fg   = "#9aa5ce";
    white       = "#ffffff";

    # Semantic aliases
    accent      = "#7aa2f7";
    error       = "#f7768e";
    warn        = "#e0af68";
    success     = "#9ece6a";
    muted       = "#565f89";
  };

  fonts = {
    mono = "JetBrainsMono Nerd Font";
    size = {
      small  = 11;
      normal = 12;
      medium = 14;
      large  = 18;
    };
  };

  opacity = {
    terminal  = 0.95;
    panel     = 0.85;
    dashboard = 0.6;
  };

  border = {
    width = 2;
    radius = {
      small  = 8;
      medium = 12;
      large  = 16;
    };
  };
}
