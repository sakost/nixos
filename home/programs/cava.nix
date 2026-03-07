# Cava audio visualizer with TokyoNight gradient
{ theme, pkgs, ... }:

let
  c = theme.colors;
  # Strip # from hex color for cava config
  hex = color: builtins.substring 1 6 color;
in
{
  home.packages = [ pkgs.cava ];

  xdg.configFile."cava/config".text = ''
    [general]
    framerate = 60
    bars = 50
    bar_width = 2
    bar_spacing = 1

    [input]
    method = pipewire
    source = auto

    [output]
    method = ncurses

    [color]
    gradient = 1
    gradient_count = 4
    gradient_color_1 = '#${hex c.blue}'
    gradient_color_2 = '#${hex c.magenta}'
    gradient_color_3 = '#${hex c.cyan}'
    gradient_color_4 = '#${hex c.green}'

    [smoothing]
    noise_reduction = 77
  '';
}
