# Hyprland autostart programs and user services
{ pkgs, lib, ... }:

let
  # Wait for awww-daemon socket, then apply the first image found under
  # ~/Pictures/wallpapers (sorted) as the default wallpaper.
  setDefaultWallpaper = pkgs.writeShellScript "set-default-wallpaper" ''
    set -u
    WALLPAPERS="$HOME/Pictures/wallpapers"
    AWWW="${pkgs.awww}/bin/awww"

    # Wait up to ~3s for the daemon to accept queries
    for _ in $(seq 1 30); do
      "$AWWW" query >/dev/null 2>&1 && break
      sleep 0.1
    done

    [ -d "$WALLPAPERS" ] || exit 0

    # Prefer an explicit default symlink if present, else first file sorted
    if [ -e "$WALLPAPERS/default" ]; then
      DEFAULT=$(readlink -f "$WALLPAPERS/default" || true)
    else
      DEFAULT=$(find "$WALLPAPERS" -maxdepth 2 -type f \( \
        -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' -o -name '*.webp' \
      \) 2>/dev/null | sort | head -1)
    fi

    [ -n "$DEFAULT" ] && [ -f "$DEFAULT" ] && \
      "$AWWW" img "$DEFAULT" --transition-type fade --transition-duration 1
  '';
in

{
  wayland.windowManager.hyprland.settings = {
    # Autostart (waybar is managed by home-manager systemd service)
    # GUI apps use "uwsm app --" to get proper systemd scope isolation
    # (prevents NOTIFY_SOCKET hijacking that can crash Hyprland)
    exec-once = [
      "awww-daemon"
      "${setDefaultWallpaper}"
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
