# Walker — Wayland-native application launcher
{ theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;

  themeCss = ''
    .box-wrapper {
      background: ${rgba c.bg 0.95};
      border: 1px solid rgba(255, 255, 255, 0.08);
      border-radius: 20px;
      padding: 12px;
      box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
      font-family: "${theme.fonts.mono}", monospace;
      font-size: ${toString theme.fonts.size.medium}px;
      color: ${c.fg};
    }

    .input {
      background: ${rgba c.surface0 0.8};
      border: 1px solid rgba(255, 255, 255, 0.06);
      border-radius: 12px;
      padding: 12px 18px;
      margin: 4px 8px;
      color: ${c.fg};
      caret-color: ${c.accent};
      font-size: 16px;
    }

    .input:focus {
      border-color: ${rgba c.accent 0.5};
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
      background: linear-gradient(135deg, ${rgba c.surface1 0.8}, ${rgba c.surface0 0.6});
      border: 1px solid ${rgba c.magenta 0.3};
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
      background: ${rgba c.surface0 0.5};
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
        default = [ "desktopapplications" "custom_commands" "calc" "websearch" ];
        empty = [ "desktopapplications" "custom_commands" ];
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
          { prefix = "!"; provider = "custom_commands"; }
        ];

        custom_commands = {
          entries = [
            { name = "GitHub"; cmd = "xdg-open https://github.com"; icon = "web-browser"; }
            { name = "GitLab"; cmd = "xdg-open https://gitlab.com"; icon = "web-browser"; }
            { name = "NixOS Search"; cmd = "xdg-open https://search.nixos.org/packages"; icon = "system-search"; }
            { name = "Home Manager Options"; cmd = "xdg-open https://nix-community.github.io/home-manager/options.xhtml"; icon = "preferences-system"; }
            { name = "NixOS Wiki"; cmd = "xdg-open https://wiki.nixos.org"; icon = "help-browser"; }
            { name = "YouTube"; cmd = "xdg-open https://youtube.com"; icon = "video-display"; }
          ];
        };
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
