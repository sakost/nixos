# tmux configuration with TokyoNight theme
{ theme, pkgs, ... }:

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

      # Pane navigation (vim-style, seamless with nvim splits)
      # is_vim heuristic: passes through to nvim if the foreground process is
      # vim/nvim, otherwise moves tmux panes. Uses -n (no prefix) so C-h/j/k/l
      # work anywhere, including from nvim's tmux-navigator plugin.
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

      # Pane resize
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

      # ── Walker integrations ─────────────────────────────────────────────────
      # C-a o: pick a session from all live tmux sessions via walker
      bind o run-shell "tmux-switch-walker"
      # C-a O: pick a project from ~/dev/projects + ~/nixos-config
      bind O run-shell "tmux-sessionizer"

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

      # Copy mode (vi) — yanks pipe to wl-copy for system clipboard
      bind -T copy-mode-vi v   send -X begin-selection
      bind -T copy-mode-vi y   send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
      bind -T copy-mode-vi C-v send -X rectangle-toggle

      # Mouse drag yank → wl-copy (captures mouse position for precision)
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"

      # ── Resurrect / continuum ───────────────────────────────────────────────
      # Working dir is tmpfs ($XDG_RUNTIME_DIR, per-user, mode 0700, wiped on
      # logout). Plaintext stays in RAM only. Persistent encrypted snapshots
      # are layered on top in Task 9.
      set -g @resurrect-dir "$XDG_RUNTIME_DIR/tmux-resurrect"
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-processes 'ssh btop htop watch tail less lazygit'

      # Grouped-session cleanup: after restore, kill any ephemeral client
      # sessions (named `<base>-<digits>`) that were saved — their PIDs are
      # stale; each Alacritty creates a fresh client on next launch.
      set -g @resurrect-hook-post-restore-all "${pkgs.writeShellScript "tmux-resurrect-postrestore" ''
        ${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -E -- '-[0-9]+$' \
          | ${pkgs.findutils}/bin/xargs -rn1 -I{} ${pkgs.tmux}/bin/tmux kill-session -t "{}"
      ''}"
    '';

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];
  };
}
