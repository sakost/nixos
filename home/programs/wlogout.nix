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
        background-color: ${rgba c.bg 0.75};
      }

      button {
        color: ${c.fg};
        background-color: rgba(41, 46, 66, 0.7);
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        border: 1px solid rgba(255, 255, 255, 0.06);
        border-radius: 20px;
        margin: 12px;
        transition: all 0.3s ease;
      }

      button:hover {
        background-color: rgba(59, 66, 97, 0.8);
        border: 1px solid;
      }

      button:focus {
        background-color: rgba(59, 66, 97, 0.8);
        border: 1px solid ${c.accent};
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }
      #lock:hover {
        border-color: ${c.accent};
        box-shadow: 0 0 15px ${rgba c.accent 0.3};
      }

      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }
      #logout:hover {
        border-color: ${c.yellow};
        box-shadow: 0 0 15px ${rgba c.yellow 0.3};
      }

      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }
      #suspend:hover {
        border-color: ${c.magenta};
        box-shadow: 0 0 15px ${rgba c.magenta 0.3};
      }

      #hibernate {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
      }
      #hibernate:hover {
        border-color: ${c.cyan};
        box-shadow: 0 0 15px ${rgba c.cyan 0.3};
      }

      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
      #reboot:hover {
        border-color: ${c.green};
        box-shadow: 0 0 15px ${rgba c.green 0.3};
      }

      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
      #shutdown:hover {
        border-color: ${c.red};
        box-shadow: 0 0 15px ${rgba c.red 0.3};
      }
    '';
  };
}
