# Power menu (wlogout)
{ theme, pkgs, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;
in
{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "hyprlock";
        text = "Lock";
        keybind = "k";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit";
        text = "Logout";
        keybind = "l";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];

    style = ''
      * {
        background-image: none;
        font-family: "${theme.fonts.mono}", monospace;
        font-size: ${toString theme.fonts.size.medium}px;
      }

      window {
        background-color: ${rgba c.bg theme.opacity.panel};
      }

      button {
        color: ${c.fg};
        background-color: ${rgba c.bg 0.0};
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        border: ${toString theme.border.width}px solid ${rgba c.accent 0.0};
        border-radius: ${toString theme.border.radius.large}px;
        margin: 10px;
        transition: all 0.3s ease;
      }

      button:hover {
        background-color: ${rgba c.accent 0.15};
        border: ${toString theme.border.width}px solid ${rgba c.accent 0.6};
      }

      button:focus {
        background-color: ${rgba c.accent 0.15};
        border: ${toString theme.border.width}px solid ${c.accent};
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }
      #lock:hover {
        border-color: ${c.accent};
      }

      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }
      #logout:hover {
        border-color: ${c.yellow};
      }

      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }
      #suspend:hover {
        border-color: ${c.magenta};
      }

      #hibernate {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
      }
      #hibernate:hover {
        border-color: ${c.cyan};
      }

      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
      #reboot:hover {
        border-color: ${c.green};
      }

      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
      #shutdown:hover {
        border-color: ${c.red};
      }
    '';
  };
}
