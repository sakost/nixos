# Zathura PDF reader — vim-like keybindings, TokyoNight theme
{ pkgs, ... }:

{
  programs.zathura = {
    enable = true;

    options = {
      # TokyoNight-inspired colors
      default-bg = "#1a1b26";
      default-fg = "#c0caf5";
      statusbar-bg = "#1a1b26";
      statusbar-fg = "#a9b1d6";
      inputbar-bg = "#1a1b26";
      inputbar-fg = "#c0caf5";
      notification-bg = "#1a1b26";
      notification-fg = "#c0caf5";
      notification-error-bg = "#1a1b26";
      notification-error-fg = "#f7768e";
      notification-warning-bg = "#1a1b26";
      notification-warning-fg = "#e0af68";
      highlight-color = "rgba(224,175,104,0.5)";
      highlight-active-color = "rgba(122,162,247,0.5)";
      completion-bg = "#1a1b26";
      completion-fg = "#c0caf5";
      completion-highlight-bg = "#283457";
      completion-highlight-fg = "#c0caf5";
      recolor-lightcolor = "#1a1b26";
      recolor-darkcolor = "#c0caf5";

      # Behaviour
      selection-clipboard = "clipboard";
      adjust-open = "best-fit";
      recolor = true;
      font = "JetBrainsMono Nerd Font 12";
    };
  };

  # Set as default PDF handler
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = "org.pwmt.zathura.desktop";
  };
}
