# Tmux Cheatsheet

Prefix: **C-a** (Ctrl+a). Vi-mode copy, TokyoNight theme, resurrect auto-save.

## Sessions

| Key | Action |
|-----|--------|
| `C-a o` | Switch session (walker picker — lists live tmux sessions) |
| `C-a O` | Project sessionizer (walker — scans ~/dev/projects + ~/nixos-config) |

Outside tmux, `SUPER+G o` / `SUPER+G SHIFT+o` invoke the same scripts via the Hyprland group submap.

## Windows

| Key | Action |
|-----|--------|
| `C-a c` | New window (in current directory) |
| `C-a ,` | Rename window |
| `C-a &` | Kill window |
| `C-a 0-9` | Jump to window 0-9 |
| `C-a n` | Next window |
| `C-a p` | Previous window |
| `C-a w` | Window list (interactive) |

## Panes

| Key | Action |
|-----|--------|
| `C-a \|` | Split right (vertical) |
| `C-a -` | Split down (horizontal) |
| `C-a x` | Kill pane |
| `C-a z` | Zoom pane (toggle) |
| `C-a Space` | Cycle layout |
| `C-a {` | Swap pane left |
| `C-a }` | Swap pane right |

## Pane navigation (seamless with Neovim)

| Key | Action |
|-----|--------|
| `C-h` | Left — moves in tmux OR passes through to nvim split |
| `C-j` | Down |
| `C-k` | Up |
| `C-l` | Right |

The `is_vim` heuristic detects nvim and passes C-h/j/k/l through so you always move within the active split, whether it's a tmux pane or a nvim window. The nvim plugin `vim-tmux-navigator` handles the same protocol on the Neovim side.

## Pane resize

| Key | Action |
|-----|--------|
| `C-a H` | Resize left 5 |
| `C-a J` | Resize down 5 |
| `C-a K` | Resize up 5 |
| `C-a L` | Resize right 5 |

## Copy mode (vi)

| Key | Action |
|-----|--------|
| `C-a [` | Enter copy mode |
| `v` | Begin selection |
| `y` | Yank selection → system clipboard (wl-copy) |
| `C-v` | Toggle rectangle selection |
| Mouse drag | Select → system clipboard |
| `q` | Exit copy mode |

## Scrollback in copy mode

| Key | Action |
|-----|--------|
| `C-u` / `C-d` | Page up / down |
| `C-b` / `C-f` | Half-page up / down |
| `g` / `G` | Top / bottom of history |

## Session persistence (resurrect + continuum)

- **Auto-save**: Every 15 minutes (continuum), plus on-demand: `C-a C-s` (save) / `C-a C-r` (restore)
- **Working dir**: `$XDG_RUNTIME_DIR/tmux-resurrect` (tmpfs, wiped on logout)
- **Vault**: `~/.local/state/tmux/resurrect-vault/` — age-encrypted snapshots survive reboots
- **Scrollback**: Captured in every snapshot (pane contents saved)
- **Post-restore**: Stale client sessions auto-cleaned

## Session groups (auto-launch)

Every Alacritty window attaches to a **PID-unique client session** grouped with a long-lived base session. Session name: `main` (from $HOME) or `<CWD-basename>` (from project dirs).

- Same window list across all Alacritty windows to the same base
- Independent active-window pointer per window (no tab mirroring)
- Client sessions auto-destroy on window close (`destroy-unattached on`)
- Base session survives all window closes

## Miscellaneous

| Key | Action |
|-----|--------|
| `C-a r` | Reload tmux config |
| `C-a d` | Detach (keep session running) |
| `C-a :` | Command prompt |
| `C-a ?` | List all keybindings |
