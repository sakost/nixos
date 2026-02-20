# Walker — Wayland-native application launcher
{ ... }:

let
  themeCss = ''
    /* TokyoNight-inspired dark theme for Walker */

    .box-wrapper {
      background: rgba(26, 27, 38, 0.92);
      border: 2px solid rgba(122, 162, 247, 0.6);
      border-radius: 16px;
      padding: 8px;
      font-family: "JetBrainsMono Nerd Font", monospace;
      font-size: 14px;
      color: #c0caf5;
    }

    .input {
      background: rgba(36, 40, 59, 0.9);
      border: 1px solid rgba(122, 162, 247, 0.4);
      border-radius: 12px;
      padding: 10px 16px;
      margin: 4px 8px;
      color: #c0caf5;
      caret-color: #7aa2f7;
      font-size: 16px;
    }

    .input:focus {
      border-color: rgba(122, 162, 247, 0.8);
    }

    .item-box {
      background: transparent;
      padding: 8px 12px;
      margin: 2px 0;
      border-radius: 10px;
      color: #a9b1d6;
    }

    .item-box:selected {
      background: rgba(122, 162, 247, 0.2);
      color: #c0caf5;
    }

    .item-box:hover {
      background: rgba(122, 162, 247, 0.1);
    }

    .item-subtext {
      color: rgba(169, 177, 214, 0.7);
      font-size: 12px;
    }

    .list {
      background: transparent;
      margin: 4px 0;
      padding: 0;
    }

    .activationlabel {
      background: transparent;
      color: rgba(169, 177, 214, 0.6);
      font-size: 12px;
    }

    .spinner {
      color: #7aa2f7;
    }
  '';
in
{
  services.walker = {
    enable = true;
    systemd.enable = true; # runs as service for instant startup + clipboard monitoring

    settings = {
      close_when_open = true;
      click_to_close = true;
      force_keyboard_focus = true;
      single_click_activation = true;
      theme = "tokyonight";

      shell = {
        layer = "overlay";
        anchor_top = true;
        anchor_bottom = true;
        anchor_left = true;
        anchor_right = true;
      };

      providers = {
        default = [ "desktopapplications" "calc" "websearch" ];
        empty = [ "desktopapplications" ];
        max_results = 10;

        prefixes = [
          { prefix = ";"; provider = "providerlist"; }
          { prefix = ">"; provider = "runner"; }
          { prefix = "/"; provider = "files"; }
          { prefix = "."; provider = "symbols"; }
          { prefix = "="; provider = "calc"; }
          { prefix = "@"; provider = "websearch"; }
          { prefix = ":"; provider = "clipboard"; }
          { prefix = "$"; provider = "windows"; }
        ];
      };

      keybinds = {
        close = [ "Escape" ];
        next = [ "Down" ];
        previous = [ "Up" ];
      };
    };
  };

  # Walker theme — placed as directory structure (walker expects themes/<name>/style.css)
  xdg.configFile."walker/themes/tokyonight/style.css".text = themeCss;

  # Elephant config — disable uwsm auto-detect prefix (uwsm-app exec fails
  # from elephant's process context; systemd-run scope never gets created)
  xdg.configFile."elephant/elephant.toml".text = ''
    auto_detect_launch_prefix = false
  '';
}
