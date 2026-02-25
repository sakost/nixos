# Power menu (wlogout)
{ config, pkgs, ... }:

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
      /* TokyoNight theme */
      * {
        background-image: none;
        font-family: "JetBrainsMono Nerd Font", monospace;
        font-size: 14px;
      }

      window {
        background-color: rgba(26, 27, 38, 0.85);
      }

      button {
        color: #c0caf5;
        background-color: rgba(26, 27, 38, 0.0);
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
        border: 2px solid rgba(122, 162, 247, 0.0);
        border-radius: 16px;
        margin: 10px;
        transition: all 0.3s ease;
      }

      button:hover {
        background-color: rgba(122, 162, 247, 0.15);
        border: 2px solid rgba(122, 162, 247, 0.6);
      }

      button:focus {
        background-color: rgba(122, 162, 247, 0.15);
        border: 2px solid #7aa2f7;
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }
      #lock:hover {
        border-color: #7aa2f7;
      }

      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }
      #logout:hover {
        border-color: #e0af68;
      }

      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }
      #suspend:hover {
        border-color: #bb9af7;
      }

      #hibernate {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
      }
      #hibernate:hover {
        border-color: #7dcfff;
      }

      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
      #reboot:hover {
        border-color: #9ece6a;
      }

      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
      #shutdown:hover {
        border-color: #f7768e;
      }
    '';
  };
}
