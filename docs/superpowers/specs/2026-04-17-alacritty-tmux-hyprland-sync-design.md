# Alacritty + tmux + Hyprland groups — synced tabs design

**Date:** 2026-04-17
**Status:** Approved, awaiting implementation plan

## Goal

Alacritty has no native tab support. Provide a unified "tabs" experience by:

1. Auto-launching tmux inside every Alacritty window (tabs-within-terminal).
2. Adding a Hyprland window-group submap that mirrors the tmux prefix workflow (tabs-at-compositor).
3. Integrating other tools (nvim, wl-clipboard, walker) with tmux so the result feels cohesive.
4. Keeping the cheatsheet docs in sync.

The two tab mechanisms serve different needs — tmux persists across terminal closes and survives outside a graphical session; Hyprland groups work for any app, not just terminals. Both get identical key-mnemonics so there is only one mental model.

## Non-goals

- Replacing Alacritty with a tabbed terminal.
- Multi-machine tmux session sync.
- Restoring scrollback contents across reboots (resurrect's `capture-pane-contents on` option). Layout + CWD + command-lines are enough; scrollback is deferred.

## Architecture overview

```
┌─────────────────────────────┐       ┌──────────────────────────┐
│  Hyprland compositor        │       │  tmux server (per user)  │
│  - submap "group"           │       │  - sessions              │
│  - SUPER+G entry            │       │    - "main" (SUPER+Q)    │
│  - mirrors tmux prefix keys │       │    - "<project>" (sess.) │
└──────────┬──────────────────┘       └────────────┬─────────────┘
           │ launches                              │ attached by
           ▼                                       ▼
      ┌──────────┐   shell.program   ┌──────────────────────────┐
      │ Alacritty│ ─────────────────▶│  alacritty-tmux script   │
      │ window   │                   │  (session chooser)       │
      └──────────┘                   └──────────────────────────┘

      Inside tmux panes:
           ┌────────────┐  C-h/j/k/l  ┌──────────────┐
           │ nvim       │◀──────────▶│ other panes  │
           │ (with      │  seamless   │              │
           │  tmux-nav) │             │              │
           └────────────┘             └──────────────┘
```

Three independent layers connected through small adapter scripts:

- **`alacritty-tmux`** — shell-launcher script. Picks session name from CWD. Wired as `programs.alacritty.settings.terminal.shell.program` in Nix.
- **Hyprland `group` submap** — Nix-generated Hyprland config. Pure config; no scripts needed for the group dispatchers themselves.
- **`tmux-switch-walker`**, **`tmux-sessionizer`** — adapter scripts. Invoked from both the Hyprland submap and from inside tmux (`C-a o` / `C-a O`).

## Components

### 1. Alacritty auto-launch

**File changed:** `home/programs/alacritty.nix`

- Function signature gains `pkgs` (currently `{ theme, ... }`).
- Add `alacritty-tmux` as a `pkgs.writeShellScriptBin` inline in `home/programs/alacritty.nix` (single-purpose script specific to Alacritty; no reason to split it into `scripts.nix`).
- Configure `programs.alacritty.settings.terminal.shell.program = "${alacritty-tmux}/bin/alacritty-tmux";`

**Script behavior (grouped-session pattern — fixes the mirroring limitation):**

```sh
#!/usr/bin/env bash
# Attach via a unique *grouped client session* so each Alacritty window has
# its own active-window pointer while sharing the base session's window list.
#
# - `base` is the long-lived session that owns the windows (survives detach).
# - `client` is a per-Alacritty ephemeral session grouped with `base` (shares
#   window list via tmux's session-groups feature) but has its own cursor.
# - `destroy-unattached on` is set on the CLIENT session only — it auto-cleans
#   when the Alacritty window closes. The base stays alive.
#
# Session names: `main` when launched from $HOME, else basename of CWD.
# All non-alnum chars mapped to `_` (tmux rejects `.`, `:`, space).
dir="$PWD"
if [ "$dir" = "$HOME" ]; then
  base="main"
else
  base=$(basename "$dir" | tr -c '[:alnum:]_' '_')
fi

# Ensure base exists (detached, long-lived).
tmux has-session -t "=$base" 2>/dev/null || tmux new-session -d -s "$base"

# Attach via a PID-unique client session grouped with base.
client="${base}-$$"
exec tmux new-session -A -s "$client" -t "$base" \; set destroy-unattached on
```

**Resulting behavior:**

- First Alacritty (PID 1234) from `$HOME` → creates `main` + `main-1234`; attaches to `main-1234`. Sees windows of `main`.
- Second Alacritty (PID 5678) from `$HOME` → `main` already exists, creates `main-5678`; attaches. Also sees `main`'s windows but has its *own* active-window pointer — can show a different window from #1.
- Either Alacritty closes → its client session auto-destroys (via `destroy-unattached on`). The base `main` stays, windows stay.
- `tmux ls` shows `main`, `main-1234`, `main-5678` — client sessions appear with the `<base>-<pid>` naming convention.

**Known quirks** (documented, accepted):

- `tmux ls` shows slightly more sessions than you might expect (one per live Alacritty). They're cheap (just a cursor + group pointer), but visible. Workaround: `tmux ls -f '#{==:#{session_group},}'` lists only base sessions (those not in a group — though grouped sessions also satisfy this; tmux's filter DSL makes a cleaner filter awkward). Accepted.
- `alacritty -e <cmd>` bypasses the wrapper entirely (the `-e` flag replaces the shell). This is the correct behavior for one-off scripts like `hypr-cheatsheet` — no changes needed there.
- PID collision (a new Alacritty reuses a recently-closed PID before its client session destroys) is extremely unlikely but the `-A` flag makes it idempotent — the new launch would attach to the surviving client. Accepted.

### 2. Hyprland `group` submap

**File changed:** `home/desktop/hyprland/keybindings.nix`

- Add `"$mainMod, G, submap, group"` to the `bind` list.
- Add a new `extraConfig` (or equivalent) emitting the submap:

```
submap = group
bind = , g, togglegroup
bind = , c, exec, $terminal
bind = , n, changegroupactive, f
bind = , p, changegroupactive, b
bind = , 1, changegroupactive, 1
bind = , 2, changegroupactive, 2
bind = , 3, changegroupactive, 3
bind = , 4, changegroupactive, 4
bind = , 5, changegroupactive, 5
bind = , 6, changegroupactive, 6
bind = , 7, changegroupactive, 7
bind = , 8, changegroupactive, 8
bind = , 9, changegroupactive, 9
bind = , x, killactive
bind = , h, moveoutofgroup
bind = , l, moveintogroup, r
bind = SHIFT, l, lockactivegroup, toggle
bind = , o, exec, tmux-switch-walker
bind = SHIFT, o, exec, tmux-sessionizer
bind = , escape, submap, reset
bind = , return, submap, reset
submap = reset
```

**Binding design rationale:**

- Lowercase keys map to tmux-equivalent lowercase prefix keys where possible.
- `h`/`l` are group in/out (horizontal axis — flat tab strip has no vertical).
- No `j`/`k` bindings because groups are 1-dimensional.
- `SHIFT+l` (uppercase L) for lock — matches "heavier action" convention.
- `escape` and `return` both exit — covers both finger-habits.

**Sticky vs one-shot**: chose sticky (default Hyprland submap behavior). Rationale: Hyprland submaps do not auto-exit after one action; implementing one-shot would require `submap, reset` after every single bind, doubling boilerplate. Sticky also supports multi-action flows (e.g., `n n n p` to cycle). The mental cost is one extra `Escape` per interaction, offset by gaining a visible submap indicator in the status bar.

**Waybar submap indicator** (included — visible feedback for sticky submap):

**File changed:** `home/programs/waybar.nix`

Add a new `custom/submap` module following the existing pattern (cf. `custom/notification`, `custom/media` at lines 89 / 101):

```nix
"custom/submap" = {
  format = "{}";
  return-type = "json";
  exec = pkgs.writeShellScript "waybar-submap" ''
    sig="$HYPRLAND_INSTANCE_SIGNATURE"
    socket="$XDG_RUNTIME_DIR/hypr/$sig/.socket2.sock"
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$socket" 2>/dev/null \
      | while IFS= read -r line; do
          case "$line" in
            submap\>\>*)
              name="''${line#submap>>}"
              if [ -n "$name" ]; then
                printf '{"text":"⌨ %s","class":"active","tooltip":"submap: %s (Esc to exit)"}\n' "$name" "$name"
              else
                printf '{"text":"","class":"","tooltip":""}\n'
              fi
              ;;
          esac
        done
  '';
  tooltip = true;
};
```

Insert `"custom/submap"` into `modules-left` (or `modules-right` near notifications) of `commonBar`. Status shows `⌨ group` while in submap, blank otherwise. Event-driven (no polling) — subscribes to Hyprland's socket2 and only emits on submap transitions.

### 3. Tmux integrations

#### 3a. Neovim ↔ tmux pane navigation

**File changed:** `home/programs/nixvim/plugins.nix`

- Add plugin `nvim-tmux-navigation` (alexghergh/nvim-tmux-navigation). Preferred route: `programs.nixvim.plugins.nvim-tmux-navigation.enable = true` if the nixvim module exposes it. Fallback: add via `programs.nixvim.extraPlugins` using `pkgs.vimPlugins.nvim-tmux-navigation` — the plan step verifies availability and picks the route.
- Add keymaps in `programs.nixvim.keymaps`:
  - `C-h` → `:NvimTmuxNavigateLeft<CR>`
  - `C-j` → `:NvimTmuxNavigateDown<CR>`
  - `C-k` → `:NvimTmuxNavigateUp<CR>`
  - `C-l` → `:NvimTmuxNavigateRight<CR>`

**File changed:** `home/programs/tmux.nix`

Add to `extraConfig`:

```
# Smart pane-switching that also works inside Neovim/fzf/lazygit
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
  | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?|fzf|lazygit)(diff)?$'"
bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
bind -T copy-mode-vi C-h select-pane -L
bind -T copy-mode-vi C-j select-pane -D
bind -T copy-mode-vi C-k select-pane -U
bind -T copy-mode-vi C-l select-pane -R
```

**Known conflict:** existing `bind h select-pane -L` etc. (prefix-style) stays — user can still use `C-a h`. The `C-h` (no prefix) is additive.

#### 3b. wl-copy integration for tmux copy-mode

**File changed:** `home/programs/tmux.nix`

Replace existing `bind -T copy-mode-vi y send -X copy-selection-and-cancel` with:

```
bind -T copy-mode-vi y send -X copy-pipe-and-cancel "wl-copy"
bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-no-clear "wl-copy"
```

**Dependency:** `wl-clipboard` — already in the system per the "Clipboard" entry in `CLAUDE.md`. No Nix change needed.

#### 3c. Walker session switcher

**New file:** script `tmux-switch-walker` under `home/desktop/hyprland/scripts.nix` (or a new tmux-scripts module):

```sh
#!/usr/bin/env bash
sel=$(tmux list-sessions -F '#S' 2>/dev/null | walker -d)
[ -z "$sel" ] && exit 0
tmux switch-client -t "$sel" 2>/dev/null || tmux attach -t "$sel"
```

**Tmux binding** (`home/programs/tmux.nix` `extraConfig`):

```
bind o run-shell "tmux-switch-walker"
```

**Hyprland binding**: already included in submap above (`o` key).

#### 3d. Project sessionizer

**New file:** script `tmux-sessionizer` (same home as 3c):

```sh
#!/usr/bin/env bash
SEARCH_DIRS=("$HOME/dev/projects" "$HOME/nixos-config")
sel=$(find "${SEARCH_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | walker -d)
[ -z "$sel" ] && exit 0
name=$(basename "$sel" | tr -c '[:alnum:]_' '_')
if ! tmux has-session -t="$name" 2>/dev/null; then
  tmux new-session -d -s "$name" -c "$sel"
fi
tmux switch-client -t "$name" 2>/dev/null || tmux attach -t "$name"
```

**Tmux binding** (`home/programs/tmux.nix` `extraConfig`):

```
bind O run-shell "tmux-sessionizer"
```

**Hyprland binding**: already included in submap above (`SHIFT+o`).

#### 3e. Session persistence (tmux-resurrect + continuum)

**File changed:** `home/programs/tmux.nix`

Declarative plugin install via home-manager (no TPM / no bootstrap script):

```nix
programs.tmux = {
  # ... existing config ...
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

  extraConfig = ''
    # ... existing tmux config ...

    # ── Resurrect / continuum tuning ──────────────────────────────
    set -g @resurrect-dir "$HOME/.local/state/tmux/resurrect"
    set -g @resurrect-processes 'ssh btop htop watch tail less lazygit'
    # Scrollback capture: OFF (see Open Questions). Enabling writes plaintext
    # pane contents to disk, which can include secrets.
    # set -g @resurrect-capture-pane-contents 'on'

    # Grouped-session cleanup: after restore, kill any ephemeral client
    # sessions (named `<base>-<digits>`) that were saved — their PIDs are
    # stale; each Alacritty creates a fresh client on next launch.
    set -g @resurrect-hook-post-restore-all \
      'tmux list-sessions -F "##{session_name}" 2>/dev/null | grep -E -- "-[0-9]+$" | xargs -rn1 -I{} tmux kill-session -t "{}"'
  '';
};
```

**Behavior:**

- Every 15 min, continuum writes a snapshot to `~/.local/state/tmux/resurrect/last`.
- First Alacritty launch after boot triggers continuum's auto-restore: windows come back with CWDs and the listed processes restart (ssh/btop/htop/watch/tail/less/lazygit).
- Manual save: `C-a C-s`. Manual restore: `C-a C-r`. (resurrect's default binds.)
- Post-restore hook purges stale client sessions from the snapshot.

## Cheatsheet updates

### New file: `docs/tmux-cheatsheet.md`

Full tmux reference:

- **Prefix**: `C-a` (not `C-b`). Escape time 0 so nvim mode-switch stays snappy.
- **Sessions**: auto-attached via `alacritty-tmux`; list with `C-a s` or `C-a o` (walker); sessionizer `C-a O` for project sessions.
- **Windows** (tabs): `C-a c` new, `C-a n/p` next/prev, `C-a &` close, `C-a ,` rename, `C-a 1-9` jump, `C-a w` list.
- **Panes**: `C-a |` / `C-a -` horizontal/vertical split; `C-a h/j/k/l` navigate; `C-h/C-j/C-k/C-l` navigate (no prefix, smart-nvim-aware); `C-a H/J/K/L` resize.
- **Copy-mode**: `C-a [` enter; `v` begin selection; `C-v` rectangle; `y` yank to wl-copy; `q` quit.
- **Custom**: `C-a o` walker session switcher; `C-a O` sessionizer (project picker); `C-a r` reload config.
- **Config**: file paths to `home/programs/tmux.nix` for editing.
- **Search roots**: note the sessionizer scans `~/dev/projects` and `~/nixos-config`.

### Update: `docs/hyprland-cheatsheet.md`

- Insert new section **"Window Groups (tabs)"** between "Windows" and "Focus" sections. Include the full 11-row submap table from the submap spec above.
- Edit the `Super + Q` row in "Apps & Session" from `Open terminal (Alacritty)` to `Open terminal (Alacritty + tmux session "main")`.
- Add intro note: "For in-terminal tabs, see `tmux-cheatsheet.md` (`Super + F1` → select it)."

### Update: `docs/terminal-cheatsheet.md`

Add new **"tmux"** section near the top (before eza):

- Link to `tmux-cheatsheet.md` for full reference.
- Note: Alacritty auto-starts tmux via `alacritty-tmux` wrapper — session name is `main` from `$HOME`, else `basename $PWD`.
- Note: bypass tmux for one-off commands via `alacritty -e <cmd>` (the `-e` flag replaces the shell).

## Files touched summary

| File | Change |
|---|---|
| `home/programs/alacritty.nix` | Add `pkgs` arg, add `alacritty-tmux` script (grouped-session), wire into `shell.program` |
| `home/programs/tmux.nix` | Add nvim-nav binds, swap yank for wl-copy, add `o` / `O` binds, add `plugins` (resurrect + continuum), resurrect tuning |
| `home/programs/nixvim/plugins.nix` | Add `nvim-tmux-navigation` plugin + C-h/j/k/l keymaps |
| `home/programs/waybar.nix` | Add `custom/submap` module, include it in `commonBar.modules-*` |
| `home/desktop/hyprland/keybindings.nix` | Add `SUPER+G` submap entry + submap body |
| `home/desktop/hyprland/scripts.nix` | Add `tmux-switch-walker`, `tmux-sessionizer` scripts + include in package list |
| `docs/tmux-cheatsheet.md` | New file |
| `docs/hyprland-cheatsheet.md` | Add "Window Groups" section, tweak intro + `Super+Q` row |
| `docs/terminal-cheatsheet.md` | Add "tmux" section |

## Testing / validation

After `nrs`:

1. `SUPER + Q` from desktop → Alacritty opens, attached to a client session `main-<pid>` grouped with `main`. `C-a c` adds a new tmux window. Close Alacritty: `tmux ls` shows `main` still alive, client session gone.
2. `SUPER + Q` a second time → new client session `main-<pid2>`. Switch to a different window in window #2 (`C-a 2`): window #1 stays on its original window. Independence confirmed.
3. `SUPER + G` → waybar shows `⌨ group` indicator. Inside submap: `c` spawns new Alacritty; `n`/`p` cycle tabs; `escape` exits → indicator disappears.
4. With two split nvim panes inside a single tmux pane, and another tmux pane beside: `C-h` in nvim moves nvim-left; `C-h` again at leftmost nvim split moves to the left tmux pane.
5. In tmux copy-mode, select text with `v`, press `y`, then `SUPER+V` (walker clipboard) → yanked text is in clipboard history.
6. `C-a o` → walker shows session list. Pick one → client switches.
7. `C-a O` (or `SUPER+G SHIFT+o`) → walker shows project dirs. Pick one → session created + attached.
8. Reboot, then `SUPER + Q` → continuum auto-restores the last snapshot (windows, CWDs, configured processes restart). `tmux ls` shows the restored base session + a new client `main-<new-pid>`. Any stale client sessions from the snapshot are gone (post-restore hook).
9. `SUPER + F1` → `tmux-cheatsheet.md` is in the list; opens with `mdcat`.

## Open questions

- **Scrollback capture via resurrect** (`@resurrect-capture-pane-contents 'on'`): **not enabled by default**. Rationale: it writes every pane's visible buffer to plaintext files in `~/.local/state/tmux/resurrect/`. Panes commonly contain: kubectl tokens, git credentials echoed by CI, `env` dumps, SSH banners, secret values pasted during debugging, etc. Persisting them in plaintext survives tmux restarts but also survives threat models (backup sweeps, filesystem snapshots, accidental sync to cloud). Weigh against the benefit: seeing yesterday's terminal history after a reboot. **Decision: leave off; user can toggle by uncommenting the line in `tmux.nix` if they decide the UX win beats the secret-leakage surface.**
- **tmux-resurrect save strategy for nvim sessions**: if you use `:mksession` in nvim, adding `set -g @resurrect-strategy-nvim 'session'` makes restore re-open the same buffers. Not included by default — nothing in the current nixvim config writes session files.
