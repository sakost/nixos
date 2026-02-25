# Walker — Wayland-native application launcher
{ theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;

  themeCss = ''
    .box-wrapper {
      background: ${rgba c.bg 0.92};
      border: ${toString theme.border.width}px solid ${rgba c.accent 0.6};
      border-radius: ${toString theme.border.radius.large}px;
      padding: 8px;
      font-family: "${theme.fonts.mono}", monospace;
      font-size: ${toString theme.fonts.size.medium}px;
      color: ${c.fg};
    }

    .input {
      background: ${rgba c.bg-light 0.9};
      border: 1px solid ${rgba c.accent 0.4};
      border-radius: ${toString theme.border.radius.medium}px;
      padding: 10px 16px;
      margin: 4px 8px;
      color: ${c.fg};
      caret-color: ${c.accent};
      font-size: 16px;
    }

    .input:focus {
      border-color: ${rgba c.accent 0.8};
    }

    .item-box {
      background: transparent;
      padding: 8px 12px;
      margin: 2px 0;
      border-radius: 10px;
      color: ${c.fg-dim};
    }

    child:selected .item-box,
    row:selected .item-box {
      background: ${rgba c.accent 0.2};
      color: ${c.white};
    }

    child:selected .item-box *,
    row:selected .item-box * {
      color: ${c.white};
    }

    child:selected .item-subtext,
    row:selected .item-subtext {
      color: ${rgba c.white 0.8};
    }

    child:selected .activationlabel,
    row:selected .activationlabel {
      color: ${rgba c.white 0.8};
    }

    child:hover .item-box {
      background: ${rgba c.accent 0.1};
    }

    .item-subtext {
      color: ${rgba c.fg-dim 0.7};
      font-size: 12px;
    }

    .list {
      background: transparent;
      margin: 4px 0;
      padding: 0;
    }

    .activationlabel {
      background: transparent;
      color: ${rgba c.fg-dim 0.6};
      font-size: 12px;
    }

    .spinner {
      color: ${c.accent};
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
