# Alacritty + tmux + Hyprland tabs sync — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Alacritty's missing tab feature with a unified "tabs" experience — tmux inside every terminal for in-process tabs, and a Hyprland `SUPER+G` submap that mirrors tmux keys for compositor-level tabbing — while integrating nvim seamless pane navigation, wl-copy yanks, a walker session switcher, a project sessionizer, and encrypted session persistence via tmux-resurrect with an age-encrypted vault.

**Architecture:** Three independent layers meet at small adapter scripts.
1. `alacritty-tmux` launcher wires every Alacritty window to a per-PID *client* session grouped with a long-lived base session — giving independent active-window pointers while sharing a window list. The same script decrypts any age-encrypted resurrect snapshot from the persistent vault into `$XDG_RUNTIME_DIR` before tmux starts.
2. A Hyprland submap `group` (entered by `SUPER+G`) exposes native `togglegroup`/`changegroupactive` dispatchers under keys that mnemonically match tmux's prefix (`c`, `n`/`p`, `1`–`9`, `x`, `h`/`l`, `o`, `SHIFT+o`).
3. tmux extensions: nvim-aware `C-h/j/k/l` pane navigation (via `is_vim` heuristic), `y` yanks to wl-copy, `C-a o` walker session switcher, `C-a O` walker project sessionizer, tmux-resurrect + continuum with the working dir on tmpfs and 15-minute snapshots encrypted at rest with age.

Waybar gains a `custom/submap` indicator so the sticky submap is visible. Cheatsheets track every new binding.

**Tech Stack:** NixOS 25.05 unstable, home-manager, nixvim, Hyprland 0.54+, tmux (already configured with `C-a` prefix + TokyoNight + vi mode), waybar, walker, wl-clipboard, age (ssh-to-age pubkey already in `.sops.yaml`), vim-tmux-navigator (`pkgs.vimPlugins.vim-tmux-navigator`), pkgs.tmuxPlugins.{resurrect,continuum}.

**Spec:** `docs/superpowers/specs/2026-04-17-alacritty-tmux-hyprland-sync-design.md`

---

## File structure

| File | Change | Responsibility |
|---|---|---|
| `home/programs/alacritty.nix` | modify | Define `alacritty-tmux` launcher (grouped session + vault decrypt); wire `terminal.shell.program` |
| `home/programs/tmux.nix` | modify | Add nvim-nav binds, wl-copy yank, walker binds, `plugins = [ resurrect continuum ]`, resurrect tuning, vault hooks |
| `home/programs/nixvim/plugins.nix` | modify | Add `vim-tmux-navigator` via `extraPlugins` + `let g:` globals |
| `home/programs/waybar.nix` | modify | Add `custom/submap` module; include in `commonBar.modules-left` |
| `home/desktop/hyprland/keybindings.nix` | modify | Add `SUPER+G` entry bind + `extraConfig` submap block |
| `home/desktop/hyprland/scripts.nix` | modify | Add `tmux-switch-walker`, `tmux-sessionizer` scripts; append to `home.packages` |
| `docs/tmux-cheatsheet.md` | create | New tmux reference — prefix, windows, panes, copy-mode, custom binds |
| `docs/hyprland-cheatsheet.md` | modify | New "Window Groups (tabs)" section; tweak Super+Q row |
| `docs/terminal-cheatsheet.md` | modify | New "tmux" section pointing at tmux-cheatsheet.md |

---

## Conventions for every task

- **Validation command** (no sudo, fast): `cd ~/nixos-config && nix flake check --no-build` — type-checks every module without building derivations. Run after every code edit, before committing.
- **Build command** (no sudo): `cd ~/nixos-config && nixos-rebuild build --flake .#sakost-pc` — builds the system derivation, catches eval errors the flake check misses.
- **Apply command** (needs sudo): `sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc` — activates without persisting a boot entry. Non-persistent: a reboot returns to the previous generation. Run **at the end of each task** before behavioral verification.
- **Commit message style**: conventional commits. Scopes match area: `feat(alacritty): ...`, `feat(tmux): ...`, `feat(hyprland): ...`, `feat(waybar): ...`, `docs: ...`.

---

## Task 1: Hyprland `SUPER+G` submap

**Files:**
- Modify: `home/desktop/hyprland/keybindings.nix`

The submap is the simplest change with the fewest dependencies: pure Hyprland config, no external scripts yet. The `o` / `SHIFT+o` binds reference scripts that don't exist yet — they're wired now, we add the scripts in Task 3.

- [ ] **Step 1: Add the submap entry bind**

Edit `home/desktop/hyprland/keybindings.nix`. Locate the `bind = [ ... ]` list (line 61). Immediately after the `"$mainMod, F1, exec, hypr-cheatsheet"` line (around line 77), add:

```nix
      # Group submap — tmux-mirror for tab-like window groups
      "$mainMod, G, submap, group"
```

- [ ] **Step 2: Add the submap body via extraConfig**

At the end of the `keybindings.nix` module (before the closing `}` of `wayland.windowManager.hyprland.settings`), the file currently closes `bindl = [ ... ]; };`. Break out of `settings` and add a sibling `extraConfig` field on `wayland.windowManager.hyprland`.

Replace the final `};` block of the file (after `bindl`) so the structure becomes:

```nix
    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];
  };

  # Window-group submap — tabs at the compositor level, mnemonically mirrors
  # tmux's `C-a` prefix:
  #   g       togglegroup (make window a group / collapse back)
  #   c       new terminal (auto-joins group if auto_group is on)
  #   n / p   next / prev tab in group
  #   1-9     jump to tab N
  #   x       close current tab
  #   h / l   move window out of / into neighbouring group
  #   SHIFT+l lock group (prevents auto-absorption)
  #   o       walker: switch tmux session (runs tmux-switch-walker)
  #   SHIFT+o walker: project sessionizer (runs tmux-sessionizer)
  #   Escape / Return  exit submap
  wayland.windowManager.hyprland.extraConfig = ''
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
  '';
}
```

(Note the outer module returns an attrset with *two* top-level fields now: `wayland.windowManager.hyprland.settings = { ... };` and `wayland.windowManager.hyprland.extraConfig = '' ... '';`. Home-manager merges them.)

- [ ] **Step 3: Validate**

Run: `cd ~/nixos-config && nix flake check --no-build`
Expected: No errors. If it fails, check for a stray character in the heredoc or a mismatched brace.

- [ ] **Step 4: Build**

Run: `cd ~/nixos-config && nixos-rebuild build --flake .#sakost-pc`
Expected: Builds successfully. The generated `hyprland.conf` should include a `submap = group` block.

- [ ] **Step 5: Apply + verify (user-interactive step — requires sudo)**

Run: `sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc`

Then in Hyprland:
1. Open a terminal (or any window).
2. Press `SUPER+G`. Nothing visible changes yet (waybar indicator comes in Task 2). This is expected.
3. Press `g` → window converts to a 1-tab group (border becomes a group border — slightly different color per `col.group_border_active` default).
4. Press `c` → new Alacritty spawns. With default Hyprland `group:auto_group = true`, it joins the group as tab 2.
5. Press `n` / `p` to cycle tabs. Press `1` → focuses tab 1.
6. Press `Escape` → exits submap. `SUPER+1`–`9` resume switching workspaces (proving you left the submap).

Expected: group cycling works. `o` / `SHIFT+o` will no-op for now (scripts missing — Hyprland logs `exec` failure but ignores it).

- [ ] **Step 6: Commit**

```bash
cd ~/nixos-config
git add home/desktop/hyprland/keybindings.nix
git commit -m "feat(hyprland): add SUPER+G group submap mirroring tmux prefix"
```

---

## Task 2: Waybar `custom/submap` indicator

**Files:**
- Modify: `home/programs/waybar.nix`

Makes the sticky submap visible.

- [ ] **Step 1: Add `socat` to the function args and locate the custom modules block**

Open `home/programs/waybar.nix`. The file begins with a function header — confirm `pkgs` is present in the destructure. The custom modules live around line 89 (`"custom/notification"`) and line 101 (`"custom/media"`).

- [ ] **Step 2: Insert the `custom/submap` module**

After the `"custom/media" = { ... };` block (around line 109), add a new sibling:

```nix
        "custom/submap" = {
          format = "{}";
          return-type = "json";
          exec = pkgs.writeShellScript "waybar-submap" ''
            #!${pkgs.bash}/bin/bash
            sig="$HYPRLAND_INSTANCE_SIGNATURE"
            socket="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/$sig/.socket2.sock"
            # Emit a blank state on startup so waybar doesn't show stale text.
            printf '{"text":"","class":"","tooltip":""}\n'
            ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$socket" 2>/dev/null \
              | while IFS= read -r line; do
                  case "$line" in
                    submap\>\>*)
                      name="''${line#submap>>}"
                      if [ -n "$name" ]; then
                        printf '{"text":"⌨ %s","class":"active","tooltip":"Hyprland submap: %s (Esc to exit)"}\n' "$name" "$name"
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

- [ ] **Step 3: Include the module in `commonBar.modules-left`**

Locate `commonBar.modules-left` (around line 121):

```nix
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
```

Change to:

```nix
        modules-left = [ "hyprland/workspaces" "hyprland/window" "custom/submap" ];
```

- [ ] **Step 4: Validate**

Run: `cd ~/nixos-config && nix flake check --no-build`
Expected: No errors.

- [ ] **Step 5: Build**

Run: `cd ~/nixos-config && nixos-rebuild build --flake .#sakost-pc`
Expected: Builds successfully.

- [ ] **Step 6: Apply + verify (requires sudo)**

Run: `sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc`

Restart waybar to pick up the new config: `systemctl --user restart waybar` (home-manager runs waybar as a user service).

Then:
1. Press `SUPER+G` — waybar's left side should show `⌨ group`.
2. Press `Escape` — the indicator disappears.

Expected: indicator toggles in sync with the submap state.

- [ ] **Step 7: Commit**

```bash
cd ~/nixos-config
git add home/programs/waybar.nix
git commit -m "feat(waybar): add custom/submap indicator for Hyprland submaps"
```

---

## Task 3: `tmux-switch-walker` + `tmux-sessionizer` scripts

**Files:**
- Modify: `home/desktop/hyprland/scripts.nix`

These are the scripts the submap `o` / `SHIFT+o` binds already reference.

- [ ] **Step 1: Add both scripts in `scripts.nix`**

Open `home/desktop/hyprland/scripts.nix`. Find the `hypr-cheatsheet = pkgs.writeShellScriptBin ...` block (line 386). Directly after it, add:

```nix
  # Walker-backed tmux session switcher — lists running tmux sessions, on
  # select: switch the current client (inside tmux) or attach (outside).
  tmux-switch-walker = pkgs.writeShellScriptBin "tmux-switch-walker" ''
    set -eu
    if ! ${pkgs.tmux}/bin/tmux has-session 2>/dev/null; then
      exit 0
    fi
    sel=$(${pkgs.tmux}/bin/tmux list-sessions -F '#S' 2>/dev/null | ${pkgs.walker}/bin/walker -d)
    [ -z "$sel" ] && exit 0
    ${pkgs.tmux}/bin/tmux switch-client -t "$sel" 2>/dev/null \
      || ${pkgs.tmux}/bin/tmux attach -t "$sel"
  '';

  # Walker-backed project sessionizer — lists project dirs, on select:
  # create-if-missing + attach a tmux session named after the dir.
  tmux-sessionizer = pkgs.writeShellScriptBin "tmux-sessionizer" ''
    set -eu
    SEARCH_DIRS=("$HOME/dev/projects" "$HOME/nixos-config")
    sel=$(${pkgs.findutils}/bin/find "''${SEARCH_DIRS[@]}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
      | ${pkgs.walker}/bin/walker -d)
    [ -z "$sel" ] && exit 0
    name=$(basename "$sel" | tr -c '[:alnum:]_' '_')
    if ! ${pkgs.tmux}/bin/tmux has-session -t="$name" 2>/dev/null; then
      ${pkgs.tmux}/bin/tmux new-session -d -s "$name" -c "$sel"
    fi
    ${pkgs.tmux}/bin/tmux switch-client -t "$name" 2>/dev/null \
      || ${pkgs.tmux}/bin/tmux attach -t "$name"
  '';
```

- [ ] **Step 2: Add both scripts to `home.packages`**

Scroll to line 685:

```nix
  home.packages = [ hypr-autoname hypr-sync-ws hypr-ws-sync-daemon hypr-monitor-mgr usb-notify hypr-wallpaper hypr-bluetooth hypr-cheatsheet ];
```

Change to:

```nix
  home.packages = [ hypr-autoname hypr-sync-ws hypr-ws-sync-daemon hypr-monitor-mgr usb-notify hypr-wallpaper hypr-bluetooth hypr-cheatsheet tmux-switch-walker tmux-sessionizer ];
```

- [ ] **Step 3: Validate + build**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
```

Expected: clean build.

- [ ] **Step 4: Apply + verify (requires sudo)**

```bash
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

Then in a terminal:
1. `which tmux-switch-walker` → `/etc/profiles/per-user/sakost/bin/tmux-switch-walker` (or similar user profile path).
2. `which tmux-sessionizer` → similar.
3. Open tmux first: `alacritty -e tmux new-session -s scratch` in a floating window (this bypasses the auto-launch we haven't wired yet; `-e` overrides default shell).
4. Back in your main shell: run `tmux-switch-walker` → walker shows `scratch`. Select it → nothing happens visually (you're not attached to this tmux client). That's OK — it's wiring verification.
5. Run `tmux-sessionizer` → walker shows dirs from `~/dev/projects` and `~/nixos-config`. Cancel (Esc).

In Hyprland:
6. `SUPER+G o` → walker session switcher appears.
7. `SUPER+G SHIFT+o` → walker project list appears.

Expected: both scripts invoke walker; selecting items performs the expected tmux operation.

- [ ] **Step 5: Commit**

```bash
cd ~/nixos-config
git add home/desktop/hyprland/scripts.nix
git commit -m "feat(hyprland): add tmux-switch-walker + tmux-sessionizer scripts"
```

---

## Task 4: Wire tmux `C-a o` / `C-a O` binds to the new scripts

**Files:**
- Modify: `home/programs/tmux.nix`

Parallels the Hyprland submap so both entry points (`C-a`-prefix in tmux, `SUPER+G` outside) hit the same scripts.

- [ ] **Step 1: Add `run-shell` binds inside `extraConfig`**

Open `home/programs/tmux.nix`. Locate the `extraConfig = ''` block (starting line 19). After the "Reload config" block (line 44), before the "Brief pause after split" hook (line 47), insert:

```
      # ── Walker integrations ─────────────────────────────────────────────────
      # C-a o: pick a session from all live tmux sessions via walker
      bind o run-shell "tmux-switch-walker"
      # C-a O: pick a project from ~/dev/projects + ~/nixos-config
      bind O run-shell "tmux-sessionizer"
```

(tmux's default `C-a o` was "select next pane" — we override it. Pane navigation is available as `C-a h/j/k/l` already.)

- [ ] **Step 2: Validate + build**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
```

- [ ] **Step 3: Apply + verify (requires sudo)**

```bash
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

Then:
1. In Alacritty: `tmux new-session -s foo` (still manual — auto-launch comes in Task 5).
2. In another terminal: `tmux new-session -s bar -d` (detached).
3. In the first tmux: press `C-a o` → walker shows `foo`, `bar`. Select `bar` → the tmux client switches to session `bar`.
4. Press `C-a O` → walker shows project directories.

Expected: both binds invoke walker correctly.

- [ ] **Step 4: Commit**

```bash
cd ~/nixos-config
git add home/programs/tmux.nix
git commit -m "feat(tmux): add C-a o / C-a O walker binds for sessions + projects"
```

---

## Task 5: Alacritty auto-launch with grouped tmux sessions

**Files:**
- Modify: `home/programs/alacritty.nix`

Wires every Alacritty window to tmux. Uses the grouped-session pattern so two Alacritty windows attached to the same base have independent active-window pointers. (The vault-decrypt block is added in Task 9.)

- [ ] **Step 1: Add `pkgs` to the function header**

Open `home/programs/alacritty.nix`. Current header:

```nix
{ theme, ... }:
```

Change to:

```nix
{ theme, pkgs, ... }:
```

- [ ] **Step 2: Define `alacritty-tmux` via `writeShellScriptBin`**

Update the `let` block at the top of the file:

```nix
let
  c = theme.colors;
in
```

Change to:

```nix
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
    #!${pkgs.bash}/bin/bash
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
```

- [ ] **Step 3: Wire `terminal.shell.program`**

Inside `programs.alacritty.settings`, after the `window = { ... };` block (line 27), add a new sibling:

```nix
      terminal = {
        shell = {
          program = "${alacritty-tmux}/bin/alacritty-tmux";
        };
      };
```

- [ ] **Step 4: Validate + build**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
```

- [ ] **Step 5: Apply + verify (requires sudo)**

```bash
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

Then:
1. Kill any existing tmux server to start from a clean state: `tmux kill-server` (may say "no server running" — fine).
2. Press `SUPER+Q`. Alacritty opens. Inside, run `echo $TMUX` → non-empty path. Run `tmux display -p '#S'` → `main-<pid>`. Run `tmux ls` → shows `main` (base, 0 clients) + `main-<pid>` (1 client).
3. Press `SUPER+Q` again. Second Alacritty. `tmux display -p '#S'` → `main-<different-pid>`. `tmux ls` shows `main`, `main-<pid1>`, `main-<pid2>`.
4. In window 1: `C-a c` creates tmux window 2.
5. In window 2 (second Alacritty): `C-a 2` → switches to tmux window 2. `C-a 1` → back to window 1. Meanwhile window 1 stays on its own window. **Independence confirmed.**
6. Close window 1 (`exit` or window close). `tmux ls` → `main`, `main-<pid2>` (the `main-<pid1>` client auto-destroyed).
7. `alacritty -e echo hello` bypass test: runs `echo hello` directly without tmux (the `-e` flag replaces the shell).

Expected: every `SUPER+Q` attaches a fresh client to the same `main` group, with independent window cursors.

- [ ] **Step 6: Commit**

```bash
cd ~/nixos-config
git add home/programs/alacritty.nix
git commit -m "feat(alacritty): auto-launch tmux with per-window grouped sessions"
```

---

## Task 6: Neovim ↔ tmux seamless pane navigation

**Files:**
- Modify: `home/programs/nixvim/plugins.nix`
- Modify: `home/programs/tmux.nix`

Adds `pkgs.vimPlugins.vim-tmux-navigator` and tmux-side `is_vim` heuristic. `C-h/j/k/l` becomes context-aware: inside nvim it moves between nvim splits; at the edge of nvim splits it jumps to the adjacent tmux pane.

- [ ] **Step 1: Add `vim-tmux-navigator` to nixvim extraPlugins**

Open `home/programs/nixvim/plugins.nix`. Find the `programs.nixvim.extraPlugins = [ ... ];` block (line 129). Currently:

```nix
  programs.nixvim.extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "claudecode-nvim";
      src = pkgs.fetchFromGitHub {
        ...
      };
    })
  ];
```

Change to append `pkgs.vimPlugins.vim-tmux-navigator`:

```nix
  programs.nixvim.extraPlugins = [
    pkgs.vimPlugins.vim-tmux-navigator
    (pkgs.vimUtils.buildVimPlugin {
      name = "claudecode-nvim";
      src = pkgs.fetchFromGitHub {
        ...
      };
    })
  ];
```

- [ ] **Step 2: Disable the plugin's default mappings + add explicit binds**

The default plugin binds `<C-h/j/k/l>` but with `let g:tmux_navigator_no_mappings = 1` we control them explicitly. Inside `programs.nixvim.extraConfigLua` (around line 141), before the `require("claudecode").setup(...)` block, add:

```lua
    -- vim-tmux-navigator: disable default mappings; we bind explicitly below.
    vim.g.tmux_navigator_no_mappings = 1
```

- [ ] **Step 3: Add explicit keymaps**

Still in `plugins.nix`, find `programs.nixvim.keymaps = [ ... ];` (line 199). After the Trouble keymaps and before the Snacks terminal entry, add:

```nix
    # vim-tmux-navigator: seamless C-h/j/k/l across nvim splits + tmux panes
    { mode = "n"; key = "<C-h>"; action = "<cmd>TmuxNavigateLeft<CR>";  options.silent = true; options.desc = "Nav left (nvim/tmux)"; }
    { mode = "n"; key = "<C-j>"; action = "<cmd>TmuxNavigateDown<CR>";  options.silent = true; options.desc = "Nav down (nvim/tmux)"; }
    { mode = "n"; key = "<C-k>"; action = "<cmd>TmuxNavigateUp<CR>";    options.silent = true; options.desc = "Nav up (nvim/tmux)"; }
    { mode = "n"; key = "<C-l>"; action = "<cmd>TmuxNavigateRight<CR>"; options.silent = true; options.desc = "Nav right (nvim/tmux)"; }
```

- [ ] **Step 4: Add tmux-side `is_vim` heuristic + binds**

Open `home/programs/tmux.nix`. Inside `extraConfig`, after the walker integrations block added in Task 4 but before the "Brief pause after split" hook, add:

```
      # ── nvim-aware pane navigation ──────────────────────────────────────────
      # Smart pane switching: in nvim, forward C-h/j/k/l to nvim; elsewhere
      # use tmux's select-pane. Pattern from christoomey/vim-tmux-navigator.
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?|fzf|lazygit)(diff)?$'"
      bind -n 'C-h' if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n 'C-j' if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n 'C-k' if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n 'C-l' if-shell "$is_vim" "send-keys C-l" "select-pane -R"
      bind -T copy-mode-vi 'C-h' select-pane -L
      bind -T copy-mode-vi 'C-j' select-pane -D
      bind -T copy-mode-vi 'C-k' select-pane -U
      bind -T copy-mode-vi 'C-l' select-pane -R
```

- [ ] **Step 5: Validate + build**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
```

- [ ] **Step 6: Apply + verify (requires sudo)**

```bash
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

Then:
1. Open Alacritty (attaches to tmux `main-<pid>`).
2. `C-a |` to split horizontally → two tmux panes.
3. In the right pane: `nvim`.
4. In nvim: `:vsplit` → two nvim windows.
5. `C-h` → moves left inside nvim (nvim window focus).
6. `C-h` again → still at leftmost nvim window, so it jumps to the **left tmux pane** (the shell). The border on the active tmux pane updates.
7. `C-l` → back into nvim, rightmost window.

Expected: `C-h/j/k/l` navigates fluidly across the nvim/tmux boundary.

- [ ] **Step 7: Commit**

```bash
cd ~/nixos-config
git add home/programs/nixvim/plugins.nix home/programs/tmux.nix
git commit -m "feat(tmux,nvim): seamless C-h/j/k/l navigation via vim-tmux-navigator"
```

---

## Task 7: tmux yank → wl-copy

**Files:**
- Modify: `home/programs/tmux.nix`

Replace the default `copy-selection-and-cancel` with `copy-pipe-and-cancel "wl-copy"` so yanks land in the Wayland clipboard (and walker's clipboard history).

- [ ] **Step 1: Update copy-mode binds**

Open `home/programs/tmux.nix`. In `extraConfig`, find the "Copy mode (vi)" block at the end (line 79):

```
      # Copy mode (vi)
      bind -T copy-mode-vi v   send -X begin-selection
      bind -T copy-mode-vi y   send -X copy-selection-and-cancel
      bind -T copy-mode-vi C-v send -X rectangle-toggle
```

Replace the `y` bind with a `copy-pipe-and-cancel` targeting `wl-copy`, and add a mouse-drag bind:

```
      # Copy mode (vi) — yanks go to the Wayland clipboard (+ walker history).
      bind -T copy-mode-vi v   send -X begin-selection
      bind -T copy-mode-vi y   send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
      bind -T copy-mode-vi C-v send -X rectangle-toggle
      bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-no-clear "${pkgs.wl-clipboard}/bin/wl-copy"
```

Note: `pkgs` needs to be available. `tmux.nix` already accepts `{ theme, ... }` — add `pkgs` to the destructure if missing.

- [ ] **Step 2: Confirm `pkgs` is in function args**

Open the top of `home/programs/tmux.nix`. Currently:

```nix
{ theme, ... }:
```

Change to:

```nix
{ theme, pkgs, ... }:
```

- [ ] **Step 3: Validate + build + apply**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

- [ ] **Step 4: Verify**

1. In Alacritty: `seq 1 20 | less`.
2. `C-a [` → enter copy-mode. Move cursor, press `v`, select some lines, press `y`.
3. `wl-paste` → pastes the selected text. `SUPER+V` (walker clipboard) → entry at the top.
4. Triple-click a line to select, release → `wl-paste` contains that line.

Expected: both keyboard yank and mouse-drag copy land in wl-clipboard.

- [ ] **Step 5: Commit**

```bash
cd ~/nixos-config
git add home/programs/tmux.nix
git commit -m "feat(tmux): yank to wl-copy so walker clipboard history sees it"
```

---

## Task 8: tmux-resurrect + continuum on tmpfs (no encryption yet)

**Files:**
- Modify: `home/programs/tmux.nix`

Install resurrect + continuum, point the working dir at `$XDG_RUNTIME_DIR` (tmpfs), and turn scrollback capture on. **No age encryption yet** — we add that in Task 9. For this task, snapshots are plaintext in tmpfs only (wiped on logout). This is a useful intermediate state: session persistence across tmux server restarts *within* a login session.

- [ ] **Step 1: Add `plugins` to `programs.tmux`**

Open `home/programs/tmux.nix`. Currently the module is `programs.tmux = { enable = true; ... extraConfig = '' ... ''; };`. Inside that attrset (after `extraConfig`), add:

```nix
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
```

- [ ] **Step 2: Add resurrect tuning in `extraConfig`**

Append to `extraConfig` (at the very end, after the copy-mode binds):

```
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
```

- [ ] **Step 3: Ensure the tmpfs dir exists before tmux starts**

Open `home/programs/alacritty.nix`. In the `alacritty-tmux` script body (before the `tmux has-session ...` line), add the tmpfs dir creation:

```sh
    # Ensure resurrect's tmpfs working dir exists with tight perms.
    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tmux-resurrect"
    ${pkgs.coreutils}/bin/mkdir -p "$RUNTIME_DIR"
    ${pkgs.coreutils}/bin/chmod 700 "$RUNTIME_DIR"
```

Insert this between the session-name computation and the `tmux has-session` line.

- [ ] **Step 4: Validate + build + apply**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

- [ ] **Step 5: Verify**

1. `tmux kill-server`. Press `SUPER+Q`. Inside: `ls $XDG_RUNTIME_DIR/tmux-resurrect/` → empty (no snapshot yet).
2. `C-a c` a few times to add windows. Run a few commands to accumulate scrollback.
3. `C-a C-s` → resurrect saves. `ls $XDG_RUNTIME_DIR/tmux-resurrect/` → shows a `tmux_resurrect_*.txt` file, several `pane-*.txt` files (scrollback), and `last` symlink.
4. `tmux kill-server`. Press `SUPER+Q` again. Continuum's `@continuum-restore 'on'` should trigger an auto-restore → windows + scrollback come back.
5. `tmux ls` → base + new client. Any `main-<old-pid>` from the snapshot should have been killed by the post-restore hook.
6. **Do NOT reboot yet** — without the vault (Task 9), `$XDG_RUNTIME_DIR` wipes on logout and snapshots are lost.

Expected: session restore works within a login session; scrollback is captured.

- [ ] **Step 6: Commit**

```bash
cd ~/nixos-config
git add home/programs/tmux.nix home/programs/alacritty.nix
git commit -m "feat(tmux): add resurrect + continuum on tmpfs with scrollback capture"
```

---

## Task 9: Age-encrypted persistent vault for resurrect snapshots

**Files:**
- Modify: `home/programs/tmux.nix`
- Modify: `home/programs/alacritty.nix`

Layer persistent encryption on top of Task 8: after each save, encrypt the snapshot to `~/.local/state/tmux/resurrect-vault/snapshot-<ts>.age`; on first launch after boot, `alacritty-tmux` decrypts `latest` back into tmpfs.

- [ ] **Step 1: Add the post-save encrypt hook in tmux.nix**

Open `home/programs/tmux.nix`. In `extraConfig`, inside the "Resurrect / continuum" block (added in Task 8), after the `@resurrect-processes` line and before the post-restore hook, add:

```
      # Age pubkey from .sops.yaml — user-level key derived from SSH host
      # key via ssh-to-age. Private counterpart: ~/.ssh/id_ed25519.
      set -g @resurrect-hook-post-save-all "${pkgs.writeShellScript "tmux-resurrect-vault-save" ''
        set -euo pipefail
        RDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/tmux-resurrect"
        VDIR="$HOME/.local/state/tmux/resurrect-vault"
        AGE_PUBKEY='age18vd0kqpadtu3uj8ztha98k4pwfxcgp9z7f5dzeumjkezywzvtgvqzrp6wy'
        ${pkgs.coreutils}/bin/mkdir -p "$VDIR"
        ${pkgs.coreutils}/bin/chmod 700 "$VDIR"
        latest=$(${pkgs.coreutils}/bin/readlink -f "$RDIR/last" 2>/dev/null || true)
        if [ -z "$latest" ] || [ ! -r "$latest" ]; then
          exit 0
        fi
        ts=$(${pkgs.coreutils}/bin/basename "$latest" .txt | ${pkgs.gnused}/bin/sed 's/^tmux_resurrect_//')
        out="$VDIR/snapshot-''${ts}.age"
        ${pkgs.age}/bin/age -r "$AGE_PUBKEY" -o "$out" "$latest"
        ln -sfn "$(${pkgs.coreutils}/bin/basename "$out")" "$VDIR/latest"
        # Keep only the 5 most recent vault snapshots.
        ls -1t "$VDIR"/snapshot-*.age 2>/dev/null \
          | ${pkgs.coreutils}/bin/tail -n +6 \
          | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/rm -f
      ''}"
```

- [ ] **Step 2: Add the vault-decrypt block to `alacritty-tmux`**

Open `home/programs/alacritty.nix`. In the `alacritty-tmux` script body, between the `mkdir -p "$RUNTIME_DIR" && chmod 700 ...` line (from Task 8) and the `tmux has-session ...` line, insert the vault-restore block:

```sh
    # --- Resurrect vault decrypt ----------------------------------
    # If a persistent vault snapshot exists but the tmpfs working dir
    # is empty (fresh boot), decrypt the latest snapshot into tmpfs
    # BEFORE tmux starts — so continuum's auto-restore finds plaintext.
    VAULT_DIR="$HOME/.local/state/tmux/resurrect-vault"
    if [ ! -e "$RUNTIME_DIR/last" ] && [ -L "$VAULT_DIR/latest" ]; then
      enc=$(${pkgs.coreutils}/bin/readlink -f "$VAULT_DIR/latest" 2>/dev/null || true)
      if [ -n "$enc" ] && [ -r "$enc" ]; then
        ts=$(${pkgs.coreutils}/bin/basename "$enc" .age | ${pkgs.gnused}/bin/sed 's/^snapshot-//')
        out="$RUNTIME_DIR/tmux_resurrect_''${ts}.txt"
        if ${pkgs.age}/bin/age -d -i "$HOME/.ssh/id_ed25519" -o "$out" "$enc" 2>/dev/null; then
          ln -sfn "$(${pkgs.coreutils}/bin/basename "$out")" "$RUNTIME_DIR/last"
        fi
      fi
    fi
    # --------------------------------------------------------------
```

- [ ] **Step 3: Validate + build + apply**

```bash
cd ~/nixos-config
nix flake check --no-build
nixos-rebuild build --flake .#sakost-pc
sudo nixos-rebuild test --flake ~/nixos-config#sakost-pc
```

- [ ] **Step 4: Verify save-encrypt flow**

1. `tmux kill-server`. Press `SUPER+Q`. Create some windows: `C-a c` a few times, run a command in each.
2. `C-a C-s` → save.
3. `ls -la ~/.local/state/tmux/resurrect-vault/` → should show one `snapshot-<ts>.age` file and a `latest` symlink pointing at it.
4. `file ~/.local/state/tmux/resurrect-vault/snapshot-*.age` → reports "data" (binary). `head -c 20 ~/.local/state/tmux/resurrect-vault/snapshot-*.age` shows the age header `age-encryption.org/v1`.
5. Verify scrollback is inside: manually decrypt to see it's the plaintext resurrect format: `age -d -i ~/.ssh/id_ed25519 ~/.local/state/tmux/resurrect-vault/latest | head`. Expected: lines starting with `window`, `pane`, etc.

- [ ] **Step 5: Verify reboot-decrypt flow (may need actual reboot — otherwise simulate with a tmpfs wipe)**

Simulation path (fast):
1. `tmux kill-server`.
2. `rm -rf $XDG_RUNTIME_DIR/tmux-resurrect` (simulate logout wipe).
3. Press `SUPER+Q`. `alacritty-tmux` should detect the empty runtime dir + existing vault, decrypt, and tmux auto-restores.
4. Inside the new tmux: `tmux list-windows` → shows all the windows from before step 1. Scroll up in each pane: scrollback from before is there.
5. `ls $XDG_RUNTIME_DIR/tmux-resurrect/` → shows the decrypted plaintext file.

Full reboot path (real validation):
6. Later, when convenient, actually reboot. On first `SUPER+Q` post-boot, the same decrypt flow runs.

Expected: snapshot survives tmpfs wipes via the encrypted vault; restore is transparent.

- [ ] **Step 6: Commit**

```bash
cd ~/nixos-config
git add home/programs/tmux.nix home/programs/alacritty.nix
git commit -m "feat(tmux): age-encrypted persistent vault for resurrect snapshots"
```

---

## Task 10: `docs/tmux-cheatsheet.md` (new)

**Files:**
- Create: `docs/tmux-cheatsheet.md`

The cheatsheet launcher (`hypr-cheatsheet`) auto-discovers `*.md` files in `docs/` — creating this file makes it immediately available via `SUPER+F1`.

- [ ] **Step 1: Write the cheatsheet**

Create `docs/tmux-cheatsheet.md` with this content:

```markdown
# tmux Cheatsheet

Terminal multiplexer providing in-terminal tabs (called "windows") and pane splits. Auto-launched by Alacritty via the `alacritty-tmux` wrapper.

- **Prefix key**: `Ctrl + a` (not the default `Ctrl + b`)
- **Config**: `home/programs/tmux.nix`
- **Session naming**: `main` when launched from `$HOME`; otherwise `basename $PWD` (non-alnum → `_`)
- **Client grouping**: each Alacritty attaches as a per-PID client session grouped with the base — independent active-window pointer, shared window list.
- **Bypass**: `alacritty -e <command>` skips tmux entirely (the `-e` flag replaces the shell).

## Sessions

| Key | Action |
|-----|--------|
| `C-a s` | List sessions (built-in tree view) |
| `C-a o` | Walker session switcher (custom) |
| `C-a O` | Walker project sessionizer — scans `~/dev/projects` and `~/nixos-config` (custom) |
| `C-a $` | Rename current session |
| `C-a d` | Detach from session |
| `C-a C-s` | Manual save (tmux-resurrect) |
| `C-a C-r` | Manual restore (tmux-resurrect) |

## Windows (tabs)

| Key | Action |
|-----|--------|
| `C-a c` | New window |
| `C-a n` / `C-a p` | Next / previous window |
| `C-a 1`–`9` | Jump to window N |
| `C-a ,` | Rename current window |
| `C-a &` | Close current window (prompts) |
| `C-a w` | Window picker (across sessions) |
| `C-a f` | Find window by text |

## Panes (splits)

| Key | Action |
|-----|--------|
| `C-a \|` | Split horizontally (custom; keeps CWD) |
| `C-a -` | Split vertically (custom; keeps CWD) |
| `C-a h`/`j`/`k`/`l` | Navigate panes with prefix |
| `C-h`/`C-j`/`C-k`/`C-l` | **Seamless navigation, no prefix** — crosses nvim split boundary (custom) |
| `C-a H`/`J`/`K`/`L` | Resize pane by 5 (custom, repeatable) |
| `C-a x` | Close current pane (prompts) |
| `C-a z` | Toggle pane zoom |
| `C-a !` | Break pane out into its own window |
| `C-a {` / `C-a }` | Swap pane with prev / next |
| `C-a Space` | Cycle pane layouts |

## Copy mode (vi keys)

| Key | Action |
|-----|--------|
| `C-a [` | Enter copy mode |
| `v` | Begin selection |
| `C-v` | Toggle rectangle (block) selection |
| `y` | **Yank to `wl-copy`** — text lands in Wayland clipboard + walker history (custom) |
| `Esc` / `q` | Exit copy mode |
| `/` / `?` | Forward / backward search |
| `n` / `N` | Next / previous match |

Mouse-drag-release also yanks to `wl-copy` (custom).

## Reload config

| Key | Action |
|-----|--------|
| `C-a r` | Source `~/.config/tmux/tmux.conf` (custom) |

## Session persistence (tmux-resurrect + continuum)

- Every 15 min, continuum saves the session state to `$XDG_RUNTIME_DIR/tmux-resurrect/` (tmpfs — RAM only).
- A save-hook encrypts the snapshot with `age` and writes `~/.local/state/tmux/resurrect-vault/snapshot-<ts>.age` + a `latest` symlink. Keeps 5 most recent.
- On first Alacritty launch after reboot/logout, `alacritty-tmux` decrypts the vault back into tmpfs; continuum auto-restores windows, CWDs, listed processes (`ssh btop htop watch tail less lazygit`), and **scrollback**.
- Age key: user-level pubkey from `.sops.yaml`. Private key: `~/.ssh/id_ed25519`.

## Notes

- `tmux ls` shows both the base session (e.g., `main`) and each live Alacritty's client session (e.g., `main-1234`). Client sessions have `destroy-unattached on` and auto-clean when their Alacritty closes.
- To intentionally unlink from the shared base: press `SUPER+G SHIFT+o` (sessionizer) and pick a project, or create a fresh named session with `C-a :new -s <name>`.
```

- [ ] **Step 2: Verify it renders via the cheatsheet launcher**

```bash
cd ~/nixos-config
# No rebuild needed — hypr-cheatsheet finds *.md in docs/ at runtime.
```

Press `SUPER+F1` in Hyprland → walker should list `tmux-cheatsheet.md` → select → floating Alacritty opens with `mdcat` rendering.

- [ ] **Step 3: Commit**

```bash
cd ~/nixos-config
git add docs/tmux-cheatsheet.md
git commit -m "docs: add tmux-cheatsheet.md covering prefix, windows, panes, resurrect"
```

---

## Task 11: Update `docs/hyprland-cheatsheet.md`

**Files:**
- Modify: `docs/hyprland-cheatsheet.md`

- [ ] **Step 1: Add intro reference to tmux-cheatsheet**

Open `docs/hyprland-cheatsheet.md`. Line 1 is `# Hyprland Cheatsheet`. Line 3 is `Mod key: **Super** (Windows key)`. Insert two lines after line 3:

```markdown

For in-terminal tabs, see [`tmux-cheatsheet.md`](tmux-cheatsheet.md) (`Super + F1` → select it from the list).
```

- [ ] **Step 2: Update the `Super + Q` row**

Find the row in the "Apps & Session" table:

```markdown
| `Super + Q` | Open terminal (Alacritty) |
```

Change to:

```markdown
| `Super + Q` | Open terminal (Alacritty + tmux session `main` auto-attached) |
```

- [ ] **Step 3: Insert new "Window Groups (tabs)" section**

Locate the end of the "Windows" section (the line after `| `Super + J` | Toggle split direction (dwindle) |`, which is the last row of that table). Insert a new section before "## Focus":

```markdown
## Window Groups (tabs)

Press `Super + G` to enter the `group` submap (mirrors tmux's `C-a` prefix). Waybar shows `⌨ group` while active. Stay in the submap until `Escape`/`Return`.

| Key (inside submap) | Action | tmux equivalent |
|---------------------|--------|-----------------|
| `g` | Toggle window into / out of a group | (implicit) |
| `c` | Spawn new terminal (auto-joins group) | `C-a c` |
| `n` / `p` | Next / previous tab | `C-a n` / `C-a p` |
| `1`–`9` | Jump to tab N | `C-a 1`–`C-a 9` |
| `x` | Close current tab | `C-a &` |
| `h` / `l` | Move window out of / into neighbouring group | — |
| `Shift + l` | Lock group (prevents auto-absorption) | — |
| `o` | Walker: switch tmux session | `C-a o` |
| `Shift + o` | Walker: project sessionizer | `C-a O` |
| `Escape` / `Return` | Exit submap | — |

```

- [ ] **Step 4: Commit**

```bash
cd ~/nixos-config
git add docs/hyprland-cheatsheet.md
git commit -m "docs(hyprland-cheatsheet): add Window Groups submap section"
```

---

## Task 12: Update `docs/terminal-cheatsheet.md`

**Files:**
- Modify: `docs/terminal-cheatsheet.md`

Add a short tmux section near the top pointing at the full cheatsheet.

- [ ] **Step 1: Insert tmux section before eza**

Open `docs/terminal-cheatsheet.md`. The current top section is `## eza (ls replacement)` at line 5. Insert a new section before it:

```markdown
## tmux (terminal multiplexer, auto-launched)

Config: `home/programs/tmux.nix`. Full reference: [`tmux-cheatsheet.md`](tmux-cheatsheet.md) (or `Super + F1` → select it).

- Alacritty auto-starts tmux via the `alacritty-tmux` wrapper. Session name = `main` when launched from `$HOME`, else `basename $PWD` (non-alnum mapped to `_`).
- Each Alacritty gets its own per-PID **client** session grouped with the base — independent active-window pointer, shared window list. Close the window → client session auto-destroys; base stays alive.
- To bypass tmux for a one-off command: `alacritty -e <cmd>` (the `-e` flag replaces the shell).
- Prefix key: `Ctrl + a`. New tab: `C-a c`. Walker session picker: `C-a o`. Walker project sessionizer: `C-a O`.
- Sessions persist across reboots via tmux-resurrect + continuum; snapshots encrypted at rest with age (key = your SSH key via `.sops.yaml`).

```

- [ ] **Step 2: Commit**

```bash
cd ~/nixos-config
git add docs/terminal-cheatsheet.md
git commit -m "docs(terminal-cheatsheet): add tmux section with auto-launch behavior"
```

---

## Final integration walk-through (after Task 12)

This is the end-to-end smoke test. No code changes — just confirm everything hangs together.

- [ ] Open a fresh Alacritty (`SUPER+Q`). Confirm: `echo $TMUX` non-empty, `tmux display -p '#S'` → `main-<pid>`.
- [ ] Second Alacritty (`SUPER+Q`). Switch it to a different tmux window. Confirm the two windows show different content simultaneously (grouped-session independence).
- [ ] `SUPER+G` → waybar shows `⌨ group`. `c` spawns new terminal; `n`/`p` cycle; `Escape` exits → indicator disappears.
- [ ] Nvim in one tmux pane, shell in the other. `C-h` / `C-l` jumps across the nvim↔tmux boundary.
- [ ] Tmux copy-mode `y` → `wl-paste` yields the selection. `SUPER+V` shows it in walker history.
- [ ] `C-a o` → walker session list. `C-a O` → walker project picker.
- [ ] `SUPER+G o` / `SUPER+G SHIFT+o` → same pickers from outside tmux.
- [ ] Simulate a "reboot": `tmux kill-server && rm -rf $XDG_RUNTIME_DIR/tmux-resurrect`. New `SUPER+Q` → vault decrypts, continuum restores windows + scrollback.
- [ ] `ls ~/.local/state/tmux/resurrect-vault/` shows only `.age` files + `latest` symlink. No plaintext.
- [ ] `SUPER+F1` → `tmux-cheatsheet.md` is listed; opens with mdcat.

If any of these fail, the spec's "Testing / validation" section in `docs/superpowers/specs/2026-04-17-alacritty-tmux-hyprland-sync-design.md` has the detailed diagnostic path.

After the walk-through, persist the system generation:

```bash
sudo nixos-rebuild switch --flake ~/nixos-config#sakost-pc
```

(`test` activates without adding a boot entry; `switch` makes it survive a reboot.)
