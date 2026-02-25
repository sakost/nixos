# Greetd display manager with ReGreet graphical greeter
# Uses Hyprland as wrapper compositor (instead of Cage) for proper
# multi-monitor support with different resolutions and scaling.
{ config, lib, pkgs, theme, ... }:

let
  cfg = config.custom.desktop.greetd;
  c = theme.colors;
  rgba = theme.rgba;

  greetdHyprlandConfig = pkgs.writeText "greetd-hyprland.conf" ''
    # Monitor layout (must match user session for correct positioning)
    monitor = DP-2, 3840x2160@144, 0x0, 1.5
    monitor = HDMI-A-1, 1920x1080@60, 2560x0, 1.0

    misc {
      disable_hyprland_logo = true
      disable_splash_rendering = true
      disable_watchdog_warning = true
    }

    # NVIDIA environment
    env = LIBVA_DRIVER_NAME,nvidia
    env = GBM_BACKEND,nvidia-drm
    env = __GLX_VENDOR_LIBRARY_NAME,nvidia
    env = WLR_NO_HARDWARE_CURSORS,1
    env = XCURSOR_SIZE,32
    env = GSK_RENDERER,gl

    # Disable portals (not needed for greeter, avoids xdph stall)
    env = GTK_USE_PORTAL,0
    env = GDK_DEBUG,no-portals

    # Session discovery for ReGreet
    env = XDG_DATA_DIRS,${config.services.displayManager.sessionData.desktops}/share:/run/current-system/sw/share

    # Launch ReGreet then exit Hyprland when done
    exec-once = ${pkgs.dbus}/bin/dbus-run-session ${lib.getExe config.programs.regreet.package}; ${pkgs.hyprland}/bin/hyprctl dispatch exit
  '';
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
          background: linear-gradient(160deg, ${c.bg-dark} 0%, ${c.bg} 40%, ${c.bg-light} 100%);
        }

        box#body {
          padding: 40px;
          border-radius: ${toString theme.border.radius.large}px;
          background-color: ${rgba c.bg 0.9};
          border: ${toString theme.border.width}px solid ${rgba c.accent 0.3};
          box-shadow: 0 8px 32px ${rgba c.bg-dark 0.6};
        }

        entry {
          background-color: ${c.bg-light};
          color: ${c.fg};
          border: ${toString theme.border.width}px solid ${rgba c.accent 0.4};
          border-radius: ${toString theme.border.radius.small}px;
          padding: 10px 14px;
          min-height: 20px;
        }

        entry:focus {
          border-color: ${c.bright-cyan};
          box-shadow: 0 0 6px ${rgba c.bright-cyan 0.3};
        }

        button {
          background-color: ${c.bg-light};
          color: ${c.fg};
          border: ${toString theme.border.width}px solid ${rgba c.accent 0.3};
          border-radius: ${toString theme.border.radius.small}px;
          padding: 10px 20px;
          min-height: 20px;
          min-width: 80px;
        }

        button:hover {
          background-color: ${rgba c.accent 0.15};
          border-color: ${c.accent};
        }

        button:active {
          background-color: ${rgba c.accent 0.25};
        }

        label {
          color: ${c.fg};
        }

        label.greeting {
          font-size: 24px;
          font-weight: bold;
          color: ${c.accent};
          margin-bottom: 8px;
        }

        label.clock {
          color: ${c.fg-dim};
          font-size: 16px;
        }

        combobox button {
          background-color: ${c.bg-light};
          color: ${c.fg};
          border-color: ${rgba c.accent 0.3};
          min-width: 160px;
        }

        combobox button:hover {
          border-color: ${c.accent};
        }

        .suggested-action {
          background-color: ${c.accent};
          color: ${c.bg};
          border: none;
          font-weight: bold;
          padding: 10px 28px;
        }

        .suggested-action:hover {
          background-color: ${c.bright-cyan};
        }

        .suggested-action:active {
          background-color: ${c.cyan};
        }

        .destructive-action {
          background-color: ${rgba c.red 0.15};
          color: ${c.red};
          border: ${toString theme.border.width}px solid ${rgba c.red 0.4};
        }

        .destructive-action:hover {
          background-color: ${rgba c.red 0.25};
          border-color: ${c.red};
        }
      '';
    };

    # Override default Cage command with Hyprland for multi-monitor support
    services.greetd.settings.default_session.command =
      "${pkgs.hyprland}/bin/Hyprland --config ${greetdHyprlandConfig}";
  };
}
