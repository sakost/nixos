# Hyprland autostart programs and user services
{ pkgs, lib, ... }:

let
  we = "${pkgs.linux-wallpaperengine}/bin/linux-wallpaperengine";
  weAssets = "$HOME/games/SteamLibrary/steamapps/common/wallpaper_engine/assets";
  weWorkshop = "$HOME/games/SteamLibrary/steamapps/workshop/content/431960";
in

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
      "uwsm app -- ${we} --assets-dir ${weAssets} --fps=60 --screen-root=DP-2 --bg ${weWorkshop}/3470915045"
      "uwsm app -- ${we} --assets-dir ${weAssets} --fps=60 --screen-root=HDMI-A-1 --bg ${weWorkshop}/3166146804"
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
