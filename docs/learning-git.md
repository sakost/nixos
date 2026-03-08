# Git Workflow in Neovim

Two layers of git integration: **Gitsigns** (inline, file-level) and
**LazyGit** (full TUI for everything else).

---

## Gitsigns — inline git while you code

Gutter shows `+` (added) `~` (changed) `_` (deleted) on every modified line.

### Navigation & Preview

| Key | Action |
|-----|--------|
| `]c` / `[c` | Jump to next / prev hunk |
| `Space hp` | Preview hunk diff inline |
| `Space hb` | Blame line (commit + author inline) |
| `Space tb` | Toggle persistent inline blame on all lines |
| `Space hd` | Diff this file against HEAD |
| `Space td` | Toggle showing deleted lines |

### Staging & Resetting

| Key | Action |
|-----|--------|
| `Space hs` | Stage hunk under cursor |
| `Space hu` | Undo stage hunk |
| `Space hr` | Reset hunk (discard changes) |
| `Space hS` | Stage entire buffer |
| `Space hR` | Reset entire buffer |

### Hunks as Text Objects

In visual or operator-pending mode:

| Text object | Selects |
|-------------|---------|
| `ih` | Inner hunk — the changed lines only |

```
vih     → visually select the changed lines in a hunk
dih     → discard hunk changes
yih     → yank hunk contents
```

---

## LazyGit — `Space gg`

Full terminal TUI. Keyboard-driven Git GUI. Press `?` inside any panel for
the full keybinding list.

```
Space gg   → open LazyGit
q          → quit back to Neovim
```

### Panels (navigate with arrows or hjkl)

| Panel | Shows |
|-------|-------|
| Status | Unstaged / staged files |
| Branches | Local and remote branches |
| Commits | Log with diff preview |
| Stash | Stash entries |
| Files | File tree with diff |

### Key Actions

| Key | Action |
|-----|--------|
| `Space` | Stage / unstage file or hunk |
| `a` | Stage all files |
| `c` | Commit |
| `P` | Push |
| `p` | Pull |
| `b` | Branch menu (create, checkout, delete) |
| `r` | Rebase menu |
| `s` | Stash |
| `S` | Pop stash |
| `d` | Diff view |
| `e` | Edit file in Neovim |
| `Enter` | Drill into file / commit |
| `?` | Help — full keybinding list for current panel |

### Daily Commit Workflow

1. `Space gg` — open LazyGit
2. `Space` on a file to stage it (or `a` to stage all)
3. `c` — write commit message → Enter
4. `P` — push
5. `q` — back to Neovim

### Interactive Rebase (squash / reorder commits)

1. Open Commits panel
2. Navigate to the commit you want as base
3. `r` → `i` — start interactive rebase from that point
4. Mark commits: `s` squash, `d` drop, `e` edit
5. Confirm — LazyGit handles the rest
