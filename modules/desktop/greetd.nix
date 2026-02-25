# Greetd display manager with ReGreet graphical greeter
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.desktop.greetd;
in {
  options.custom.desktop.greetd = {
    enable = lib.mkEnableOption "Greetd display manager";
  };

  config = lib.mkIf cfg.enable {
    programs.regreet = {
      enable = true;

      font = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font";
        size = 14;
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

      # TokyoNight theme
      extraCss = ''
        window {
          background-color: #1a1b26;
        }

        entry {
          background-color: #24283b;
          color: #c0caf5;
          border: 2px solid #7aa2f7;
          border-radius: 8px;
          padding: 8px 12px;
        }

        entry:focus {
          border-color: #33ccff;
          box-shadow: 0 0 4px rgba(51, 204, 255, 0.3);
        }

        button {
          background-color: #24283b;
          color: #c0caf5;
          border: 2px solid rgba(122, 162, 247, 0.4);
          border-radius: 8px;
          padding: 8px 16px;
        }

        button:hover {
          background-color: rgba(122, 162, 247, 0.15);
          border-color: #7aa2f7;
        }

        label {
          color: #c0caf5;
        }

        combobox button {
          background-color: #24283b;
          color: #c0caf5;
          border-color: rgba(122, 162, 247, 0.4);
        }

        .suggested-action {
          background-color: #7aa2f7;
          color: #1a1b26;
          border: none;
        }

        .suggested-action:hover {
          background-color: #33ccff;
        }
      '';
    };
  };
}
