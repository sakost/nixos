# Alacritty terminal configuration
{ config, pkgs, ... }:

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
        opacity = 0.95;
        padding = {
          x = 10;
          y = 10;
        };
      };

      font = {
        size = 12.0;
        normal = {
          family = "JetBrains Mono Nerd Font";
          style = "Regular";
        };
      };

      # TokyoNight color scheme
      colors = {
        primary = {
          background = "#1a1b26";
          foreground = "#c0caf5";
        };

        normal = {
          black = "#15161e";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#7dcfff";
          white = "#a9b1d6";
        };

        bright = {
          black = "#414868";
          red = "#f7768e";
          green = "#9ece6a";
          yellow = "#e0af68";
          blue = "#7aa2f7";
          magenta = "#bb9af7";
          cyan = "#7dcfff";
          white = "#c0caf5";
        };

        selection = {
          background = "#283457";
          foreground = "#c0caf5";
        };
      };
    };
  };
}
