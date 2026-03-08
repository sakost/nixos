# tmux configuration with TokyoNight theme
{ theme, ... }:

let
  c = theme.colors;
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 0;
    historyLimit = 50000;
    keyMode = "vi";
    mouse = true;
    prefix = "C-a";
    terminal = "tmux-256color";

    extraConfig = ''
      # True color support
      set -as terminal-features ",xterm-256color:RGB"

      # Renumber windows on close
      set -g renumber-windows on

      # Split panes with intuitive keys, keep current path
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      # Pane navigation (vim-style)
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Pane resize
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      # Brief pause after split to let shell initialize
      set-hook -g after-split-window "run-shell 'sleep 0.3'"

      # ── TokyoNight theme ────────────────────────────────────────────────────

      # Pane borders
      set -g pane-border-style        "fg=${c.bg-light}"
      set -g pane-active-border-style "fg=${c.accent}"

      # Status bar base
      set -g status on
      set -g status-interval 5
      set -g status-position bottom
      set -g status-style "bg=${c.bg-dark},fg=${c.fg-dim}"

      # Status left: session name
      set -g status-left-length 30
      set -g status-left "#[bg=${c.accent},fg=${c.bg-dark},bold] #S #[bg=${c.bg-dark},fg=${c.accent}]"

      # Window list (centre)
      set -g status-justify left
      set -g window-status-format         " #[fg=${c.fg-dark}]#I #[fg=${c.fg-dim}]#W "
      set -g window-status-current-format "#[bg=${c.bg-light},fg=${c.accent},bold] #I #[fg=${c.fg}]#W "
      set -g window-status-separator      ""

      # Status right: time
      set -g status-right-length 30
      set -g status-right "#[fg=${c.muted}]%H:%M #[fg=${c.accent}]%d/%m "

      # Message style
      set -g message-style       "bg=${c.bg-light},fg=${c.yellow}"
      set -g message-command-style "bg=${c.bg-light},fg=${c.cyan}"

      # Copy mode (vi)
      bind -T copy-mode-vi v   send -X begin-selection
      bind -T copy-mode-vi y   send -X copy-selection-and-cancel
      bind -T copy-mode-vi C-v send -X rectangle-toggle
    '';
  };
}
