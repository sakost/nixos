# Hyprland autostart programs and user services
{ pkgs, ... }:

{
  wayland.windowManager.hyprland.settings = {
    # Autostart (waybar is managed by home-manager systemd service)
    # GUI apps use "uwsm app --" to get proper systemd scope isolation
    # (prevents NOTIFY_SOCKET hijacking that can crash Hyprland)
    exec-once = [
      "swww-daemon"
      "uwsm app -- swaync"
      "uwsm app -- eww open dashboard"
      "uwsm app -- spotify"
    ];
  };

  systemd.user.services.telegram-desktop = {
    Unit = {
      Description = "Telegram Desktop";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.telegram-desktop}/bin/Telegram -startintray";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
