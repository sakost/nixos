# Mako notification daemon with profile/mode support
{ theme, ... }:

let
  c = theme.colors;
in
{
  services.mako = {
    enable = true;

    settings = {
      background-color = c.bg;
      text-color = c.fg;
      border-color = c.accent;
      border-radius = theme.border.radius.small;
      border-size = theme.border.width;

      font = "${theme.fonts.mono} ${toString theme.fonts.size.small}";
      icons = true;
      max-visible = 5;
      sort = "-time";

      default-timeout = 5000;
    };

    # Criteria-based rules (appended as INI sections)
    extraConfig = ''
      # Critical alerts never expire
      [urgency=critical]
      border-color=${c.error}
      default-timeout=0

      # dnd mode: silence everything
      [mode=dnd]
      invisible=1

      # work mode: silence Telegram only
      [mode=work app-name="Telegram Desktop"]
      invisible=1
    '';
  };
}
