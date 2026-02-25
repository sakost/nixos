# Greetd display manager with ReGreet graphical greeter
{ config, lib, pkgs, theme, ... }:

let
  cfg = config.custom.desktop.greetd;
  c = theme.colors;
  rgba = theme.rgba;
in {
  options.custom.desktop.greetd = {
    enable = lib.mkEnableOption "Greetd display manager";
  };

  config = lib.mkIf cfg.enable {
    programs.regreet = {
      enable = true;

      font = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = theme.fonts.mono;
        size = theme.fonts.size.medium;
      };

      cursorTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };

      settings = {
        background.fit = "Cover";

        GTK.application_prefer_dark_theme = true;

        appearance.greeting_msg = "Welcome back!";

        widget.clock = {
          format = "%a %d %b  %H:%M";
        };
      };

      extraCss = ''
        window {
          background-color: ${c.bg};
        }

        entry {
          background-color: ${c.bg-light};
          color: ${c.fg};
          border: ${toString theme.border.width}px solid ${c.accent};
          border-radius: ${toString theme.border.radius.small}px;
          padding: 8px 12px;
        }

        entry:focus {
          border-color: ${c.bright-cyan};
          box-shadow: 0 0 4px ${rgba c.bright-cyan 0.3};
        }

        button {
          background-color: ${c.bg-light};
          color: ${c.fg};
          border: ${toString theme.border.width}px solid ${rgba c.accent 0.4};
          border-radius: ${toString theme.border.radius.small}px;
          padding: 8px 16px;
        }

        button:hover {
          background-color: ${rgba c.accent 0.15};
          border-color: ${c.accent};
        }

        label {
          color: ${c.fg};
        }

        combobox button {
          background-color: ${c.bg-light};
          color: ${c.fg};
          border-color: ${rgba c.accent 0.4};
        }

        .suggested-action {
          background-color: ${c.accent};
          color: ${c.bg};
          border: none;
        }

        .suggested-action:hover {
          background-color: ${c.bright-cyan};
        }
      '';
    };
  };
}
