# Mako notification daemon — glassmorphic styling
{ theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;
in
{
  services.mako = {
    enable = true;

    settings = {
      background-color = rgba c.bg-dark 0.92;
      text-color = c.fg;
      border-color = "rgba(255, 255, 255, 0.08)";
      border-radius = theme.border.radius.large;
      border-size = 1;

      font = "${theme.fonts.mono} ${toString theme.fonts.size.small}";
      width = 380;
      icons = true;
      max-visible = 4;
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
