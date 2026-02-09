# Neovim Cheatsheet

Leader key: **Space**

## General

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl+S` | n/i | Save file |
| `Space q` | n | Quit |
| `Space Q` | n | Quit all (force) |
| `Esc` | n | Clear search highlight |
| `jk` | i | Exit insert mode |

## Window Navigation

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl+H` | n | Move to left split |
| `Ctrl+J` | n | Move to lower split |
| `Ctrl+K` | n | Move to upper split |
| `Ctrl+L` | n | Move to right split |
| `Ctrl+Up` | n | Decrease split height |
| `Ctrl+Down` | n | Increase split height |
| `Ctrl+Left` | n | Decrease split width |
| `Ctrl+Right` | n | Increase split width |

## Buffers

| Key | Mode | Action |
|-----|------|--------|
| `Shift+L` | n | Next buffer |
| `Shift+H` | n | Previous buffer |
| `Space bd` | n | Close buffer |

## Editing

| Key | Mode | Action |
|-----|------|--------|
| `Alt+J` | n/v | Move line(s) down |
| `Alt+K` | n/v | Move line(s) up |
| `<` | v | Indent left (keeps selection) |
| `>` | v | Indent right (keeps selection) |

Auto-save is enabled (triggers on focus lost, buffer leave, 1s idle).

## File Explorer (nvim-tree)

| Key | Mode | Action |
|-----|------|--------|
| `Space e` | n | Toggle file explorer |
| `Space o` | n | Focus file explorer |

## Telescope (Fuzzy Finder)

### Files

| Key | Mode | Action |
|-----|------|--------|
| `Space ff` | n | Find files |
| `Space fg` | n | Live grep (search in files) |
| `Space fb` | n | Find open buffers |
| `Space fr` | n | Recent files |
| `Space fh` | n | Help tags |

### Git

| Key | Mode | Action |
|-----|------|--------|
| `Space gc` | n | Git commits |
| `Space gs` | n | Git status |

### LSP

| Key | Mode | Action |
|-----|------|--------|
| `Space ls` | n | Document symbols |
| `Space lw` | n | Workspace symbols |
| `Space ld` | n | All diagnostics |

## LSP (Code Intelligence)

Servers: Python (pyright), Rust (rust-analyzer), TypeScript (ts_ls), Nix (nil), Go (gopls), Lua, Bash, JSON, YAML, TOML, HTML, CSS, Protobuf (buf_ls)

### Navigation

| Key | Mode | Action |
|-----|------|--------|
| `gd` | n | Go to definition |
| `gD` | n | Go to declaration |
| `gr` | n | Find references |
| `gi` | n | Go to implementation |
| `gt` | n | Go to type definition |

### Actions

| Key | Mode | Action |
|-----|------|--------|
| `K` | n | Hover documentation |
| `Space rn` | n | Rename symbol |
| `Space ca` | n | Code action |
| `Space f` | n | Format file |

### Diagnostics

| Key | Mode | Action |
|-----|------|--------|
| `Space e` | n | Show diagnostic float |
| `[d` | n | Previous diagnostic |
| `]d` | n | Next diagnostic |

Format-on-save is enabled.

## Completion (nvim-cmp)

Sources (by priority): LSP > Snippets > Buffer > Paths

| Key | Mode | Action |
|-----|------|--------|
| `Tab` | i | Next suggestion |
| `Shift+Tab` | i | Previous suggestion |
| `Enter` | i | Accept suggestion |
| `Ctrl+Space` | i | Trigger completion |
| `Ctrl+E` | i | Dismiss completion |
| `Ctrl+B` | i | Scroll docs up |
| `Ctrl+F` | i | Scroll docs down |

## Git (gitsigns)

Inline blame is shown at end of lines by default.

### Navigation

| Key | Mode | Action |
|-----|------|--------|
| `]c` | n | Next hunk |
| `[c` | n | Previous hunk |

### Staging

| Key | Mode | Action |
|-----|------|--------|
| `Space hs` | n/v | Stage hunk |
| `Space hS` | n | Stage entire buffer |
| `Space hu` | n | Undo stage hunk |

### Resetting

| Key | Mode | Action |
|-----|------|--------|
| `Space hr` | n/v | Reset hunk |
| `Space hR` | n | Reset entire buffer |

### Viewing

| Key | Mode | Action |
|-----|------|--------|
| `Space hp` | n | Preview hunk |
| `Space hb` | n | Full blame for line |
| `Space hd` | n | Diff this file |
| `Space hD` | n | Diff this file (~) |
| `Space tb` | n | Toggle inline blame |
| `Space td` | n | Toggle deleted lines |

### LazyGit

| Key | Mode | Action |
|-----|------|--------|
| `Space gg` | n | Open LazyGit |

## Trouble (Diagnostics Panel)

| Key | Mode | Action |
|-----|------|--------|
| `Space xx` | n | Toggle Trouble |
| `Space xd` | n | Buffer diagnostics only |

## Claude Code (claudecode.nvim)

Terminal opens in a right split (30% width) via snacks.nvim.

| Key | Mode | Action |
|-----|------|--------|
| `Space ac` | n | Toggle Claude terminal |
| `Space af` | n | Focus Claude terminal |
| `Space ar` | n | Resume Claude session |
| `Space aC` | n | Continue Claude session |
| `Space am` | n | Select model |
| `Space ab` | n | Add current buffer as context |
| `Space as` | v | Send selection to Claude |
| `Space aa` | n | Accept diff |
| `Space ad` | n | Deny diff |

## Markdown

| Key | Mode | Action |
|-----|------|--------|
| `Space mp` | n | Preview in Chrome |

## Tips

- Press `Space` and wait ~200ms for **which-key** popup showing all bindings
- Colorscheme: **Tokyo Night** (transparent)
- Treesitter provides syntax highlighting for: bash, c, cpp, css, dockerfile, go, html, javascript, json, lua, markdown, nix, proto, python, rust, toml, tsx, typescript, vim, yaml
