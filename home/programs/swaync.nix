# SwayNC — notification center with DND, history, and media controls
{ theme, pkgs, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;
in
{
  home.packages = [ pkgs.swaynotificationcenter ];

  # Enable swaync systemd service (starts with graphical-session, restarts on failure)
  systemd.user.services.swaync = {
    Unit = {
      Description = "Swaync notification daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      ExecReload = "${pkgs.swaynotificationcenter}/bin/swaync-client --reload-config ; ${pkgs.swaynotificationcenter}/bin/swaync-client --reload-css";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    "$schema" = "/etc/xdg/swaync/configSchema.json";
    positionX = "right";
    positionY = "top";
    layer = "overlay";
    control-center-layer = "top";
    layer-shell = true;
    cssPriority = "user";
    control-center-margin-top = 10;
    control-center-margin-bottom = 10;
    control-center-margin-right = 10;
    notification-2fa-action = true;
    notification-inline-replies = false;
    notification-window-width = 400;
    max-visible = 5;
    notification-body-image-height = 100;
    notification-body-image-width = 200;
    keyboard-shortcuts = true;
    image-visibility = "when-available";
    transition-time = 200;
    hide-on-clear = true;
    hide-on-action = true;
    widgets = [ "title" "dnd" "mpris" "notifications" ];
    widget-config = {
      title = {
        text = "Notifications";
        clear-all-button = true;
        button-text = "Clear";
      };
      dnd = {
        text = "Do Not Disturb";
      };
      mpris = {
        image-size = 96;
        image-radius = 12;
      };
    };
  };

  xdg.configFile."swaync/style.css".text = ''
    * {
      all: unset;
      font-size: 14px;
      font-family: "${theme.fonts.mono}", sans-serif;
      transition: 200ms;
    }

    /* Notifications */
    .notification-row {
      outline: none;
    }

    .notification-row:focus,
    .notification-row:hover {
      background: transparent;
    }

    .notification-background {
      box-shadow: 0 4px 12px 0 ${rgba c.bg-dark 0.5}, inset 0 0 0 1px ${rgba c.white 0.06};
      border-radius: ${toString theme.border.radius.large}px;
      margin: 12px;
      background: ${rgba c.bg-dark 0.92};
      color: ${c.fg};
      padding: 5px;
    }

    .notification-background .notification {
      padding: 10px;
      border-radius: ${toString theme.border.radius.medium}px;
    }

    .notification-background .notification.critical {
      box-shadow: inset 0 0 7px 0 ${c.red};
      border: 1px solid ${c.red};
    }

    .notification .notification-content {
      margin: 7px;
    }

    .notification-content .summary {
      color: ${c.fg};
      font-weight: bold;
      font-size: 1.1em;
    }

    .notification-content .time {
      color: ${c.fg-dim};
      font-size: 0.9em;
      margin-right: 5px;
    }

    .notification-content .body {
      color: ${c.fg-dim};
      margin-top: 4px;
    }

    .notification > *:last-child > * {
      min-height: 3.4em;
    }

    /* Close button */
    .notification-background .close-button {
      margin: 7px;
      padding: 4px;
      border-radius: 50%;
      color: ${c.bg-dark};
      background-color: ${c.red};
      min-width: 24px;
      min-height: 24px;
      box-shadow: 0 2px 4px ${rgba c.bg-dark 0.3};
    }

    .notification-background .close-button:hover {
      background-color: ${c.orange};
    }

    /* Actions */
    .notification .notification-action {
      border-radius: ${toString theme.border.radius.medium}px;
      color: ${c.fg};
      box-shadow: inset 0 0 0 1px ${rgba c.white 0.06};
      margin: 6px;
      padding: 2px 4px;
      background-color: ${rgba c.surface0 0.6};
    }

    .notification .notification-action:hover {
      background-color: ${rgba c.surface1 0.8};
      color: ${c.accent};
    }

    /* Progress */
    .notification.critical progress {
      background-color: ${c.red};
    }

    .notification.low progress,
    .notification.normal progress {
      background-color: ${c.accent};
    }

    .notification progress,
    .notification trough,
    .notification progressbar {
      border-radius: 20px;
      min-height: 6px;
    }

    /* Control center */
    .control-center {
      box-shadow: 0 0 15px 0 ${rgba c.bg-dark 0.6}, inset 0 0 0 1px ${rgba c.white 0.06};
      border-radius: ${toString theme.border.radius.xlarge}px;
      background-color: ${rgba c.bg 0.95};
      color: ${c.fg};
      padding: 18px;
      margin: 10px;
    }

    .control-center .notification-background {
      border-radius: ${toString theme.border.radius.large}px;
      box-shadow: inset 0 0 0 1px ${rgba c.white 0.06};
      margin: 8px 0;
    }

    .control-center .notification-background .notification.low {
      opacity: 0.8;
    }

    /* Title & clear button */
    .control-center .widget-title > label {
      color: ${c.fg};
      font-size: 1.4em;
      font-weight: bold;
      margin-bottom: 8px;
    }

    .control-center .widget-title button {
      border-radius: ${toString theme.border.radius.medium}px;
      color: ${c.fg};
      background-color: ${rgba c.surface0 0.6};
      box-shadow: inset 0 0 0 1px ${rgba c.white 0.06};
      padding: 8px 12px;
      font-weight: 600;
    }

    .control-center .widget-title button:hover {
      background-color: ${rgba c.surface1 0.8};
      color: ${c.yellow};
    }

    /* DND toggle */
    .widget-dnd {
      margin-top: 10px;
      border-radius: ${toString theme.border.radius.large}px;
      background: ${rgba c.surface0 0.6};
      padding: 5px 15px;
    }

    .widget-dnd > switch {
      font-size: initial;
      border-radius: 20px;
      background: ${rgba c.surface1 0.8};
      box-shadow: inset 0 0 4px ${rgba c.bg-dark 0.3};
    }

    .widget-dnd > switch:checked {
      background: ${c.accent};
    }

    .widget-dnd > switch slider {
      background: ${c.fg};
      border-radius: 50%;
      margin: 2px;
    }

    /* Scrollbar */
    scrollbar slider {
      min-width: 8px;
      margin: 0px 4px;
      background: ${c.surface2};
      border-radius: 20px;
      opacity: 0.8;
    }

    /* MPRIS (Media) */
    .widget-mpris-player {
      background: ${rgba c.surface0 0.5};
      border-radius: ${toString theme.border.radius.large}px;
      color: ${c.fg};
      padding: 10px;
      margin: 10px 0;
      box-shadow: 0 4px 10px ${rgba c.bg-dark 0.3};
    }

    .widget-mpris-album-art {
      border-radius: ${toString theme.border.radius.medium}px;
      margin-right: 15px;
    }

    .widget-mpris-title {
      font-size: 1.2rem;
      font-weight: 700;
      color: ${c.fg};
    }

    .widget-mpris-subtitle {
      font-size: 0.9rem;
      color: ${c.fg-dim};
    }

    .widget-mpris button {
      border-radius: 50%;
      color: ${c.fg};
      margin: 0 5px;
      padding: 8px;
    }

    .widget-mpris button:hover {
      background-color: ${rgba c.surface1 0.8};
      color: ${c.accent};
    }
  '';
}
