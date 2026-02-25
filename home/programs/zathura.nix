# Zathura PDF reader — vim-like keybindings
{ theme, ... }:

let
  c = theme.colors;
  rgba = theme.rgba;
in
{
  programs.zathura = {
    enable = true;

    options = {
      default-bg = c.bg;
      default-fg = c.fg;
      statusbar-bg = c.bg;
      statusbar-fg = c.fg-dim;
      inputbar-bg = c.bg;
      inputbar-fg = c.fg;
      notification-bg = c.bg;
      notification-fg = c.fg;
      notification-error-bg = c.bg;
      notification-error-fg = c.error;
      notification-warning-bg = c.bg;
      notification-warning-fg = c.warn;
      highlight-color = rgba c.yellow 0.5;
      highlight-active-color = rgba c.accent 0.5;
      completion-bg = c.bg;
      completion-fg = c.fg;
      completion-highlight-bg = c.selection;
      completion-highlight-fg = c.fg;
      recolor-lightcolor = c.bg;
      recolor-darkcolor = c.fg;

      # Behaviour
      selection-clipboard = "clipboard";
      adjust-open = "best-fit";
      recolor = true;
      font = "${theme.fonts.mono} ${toString theme.fonts.size.normal}";
    };
  };

  # Set as default PDF handler
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "org.pwmt.zathura.desktop";
  };
}
