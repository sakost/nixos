# Mako notification daemon with profile/mode support
{ ... }:

{
  services.mako = {
    enable = true;

    settings = {
      # Appearance — TokyoNight
      background-color = "#1a1b26";
      text-color = "#c0caf5";
      border-color = "#7aa2f7";
      border-radius = 8;
      border-size = 2;

      font = "JetBrainsMono Nerd Font 11";
      icons = true;
      max-visible = 5;
      sort = "-time";

      default-timeout = 5000;
    };

    # Criteria-based rules (appended as INI sections)
    extraConfig = ''
      # Critical alerts never expire
      [urgency=critical]
      border-color=#f7768e
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
