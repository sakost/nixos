# Alacritty terminal configuration
{ theme, pkgs, ... }:

let
  c = theme.colors;

  # Launcher script: attaches every Alacritty window to a *client* tmux
  # session grouped with a long-lived base session. Two Alacritty windows
  # attached to the same base see the same window list but each has its
  # own active-window pointer — no mirroring.
  #
  # Session name: `main` when launched from $HOME, else basename of CWD.
  # All non-alnum chars normalised to `_` (tmux rejects `.`, `:`, space).
  # `destroy-unattached on` is set on the client session only — it auto-
  # cleans when the Alacritty window closes, but the base stays alive.
  alacritty-tmux = pkgs.writeShellScriptBin "alacritty-tmux" ''
    set -eu
    PATH="${pkgs.tmux}/bin:${pkgs.coreutils}/bin:$PATH"

    dir="$PWD"
    if [ "$dir" = "$HOME" ]; then
      base="main"
    else
      base=$(basename "$dir" | tr -c '[:alnum:]_' '_')
    fi

    # Ensure base exists (detached; owns the window list).
    tmux has-session -t "=$base" 2>/dev/null || tmux new-session -d -s "$base"

    # PID-unique client session grouped with base.
    client="''${base}-$$"
    exec tmux new-session -A -s "$client" -t "$base" \; set destroy-unattached on
  '';
in
{
  programs.alacritty = {
    enable = true;

    settings = {
      env = {
        TERM = "xterm-256color";
      };

      scrolling = {
        history = 50000;
      };

      window = {
        decorations = "None";
        opacity = theme.opacity.terminal;
        padding = {
          x = 14;
          y = 14;
        };
      };

      terminal = {
        shell = {
          program = "${alacritty-tmux}/bin/alacritty-tmux";
        };
      };

      font = {
        size = theme.fonts.size.normal * 1.0;
        normal = {
          family = theme.fonts.mono;
          style = "Regular";
        };
      };

      colors = {
        primary = {
          background = c.bg;
          foreground = c.fg;
        };

        normal = {
          black   = c.bg-dark;
          red     = c.red;
          green   = c.green;
          yellow  = c.yellow;
          blue    = c.blue;
          magenta = c.magenta;
          cyan    = c.cyan;
          white   = c.fg-dim;
        };

        bright = {
          black   = c.bright-black;
          red     = c.red;
          green   = c.green;
          yellow  = c.yellow;
          blue    = c.blue;
          magenta = c.magenta;
          cyan    = c.cyan;
          white   = c.fg;
        };

        selection = {
          background = c.selection;
          foreground = c.fg;
        };
      };
    };
  };
}
