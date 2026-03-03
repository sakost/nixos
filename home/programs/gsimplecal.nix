# gsimplecal — lightweight calendar popup with TokyoNight styling
{ pkgs, theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;
in
{
  home.packages = [ pkgs.gsimplecal ];

  xdg.configFile."gsimplecal/config".text = ''
    show_calendar = 1
    mark_today = 1
    show_week_numbers = 1
    close_on_unfocus = 0
    mainwindow_decorated = 0
    mainwindow_keep_above = 1
    mainwindow_sticky = 0
    mainwindow_skip_taskbar = 1
    mainwindow_resizable = 0
    mainwindow_position = none
    force_lang = ru_RU.UTF-8
  '';

  # GtkCalendar colors — primarily for gsimplecal, TokyoNight palette
  gtk = {
    enable = true;
    gtk3.extraCss = ''
      calendar {
        background-color: ${c.bg};
        color: ${c.fg};
        border: none;
        padding: 8px;
      }
      calendar header {
        color: ${c.accent};
        font-weight: bold;
      }
      calendar.button {
        color: ${c.accent};
        background-color: transparent;
        border-radius: 6px;
        padding: 2px 6px;
      }
      calendar.button:hover {
        background-color: ${rgba c.accent 0.15};
      }
      calendar:selected {
        background-color: ${c.accent};
        color: ${c.bg-dark};
        border-radius: 50%;
      }
      calendar.highlight {
        color: ${c.green};
        font-weight: bold;
      }
      calendar:indeterminate {
        color: ${c.muted};
      }
    '';
  };
}
