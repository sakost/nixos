# LSP & Code Intelligence

Neovim's LSP gives real-time type info, errors, completions, and refactoring.
Same data as PyCharm, different UI. Active servers: Python (pyright), Rust,
Go, TypeScript, Nix, Lua, Bash, JSON, YAML, TOML, HTML, CSS, Protobuf.

---

## Diagnostics (errors & warnings)

Errors appear as underlines and gutter icons in real time.

| Key | Action |
|-----|--------|
| `[d` / `]d` | Jump to prev / next diagnostic |
| `Space e` | Open diagnostic in a float popup |
| `Space xx` | Open Trouble panel (all diagnostics in project) |
| `Space xd` | Trouble panel for current buffer only |

Trouble is your "Problems" panel from PyCharm. `Space xx` to open, `q` to close.

---

## Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Go to all references (opens Telescope) |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `K` | Hover documentation popup |
| `Ctrl+o` | Jump back after any `g*` navigation |

`gr` opens Telescope with every usage across the whole project, with preview.
Always use `Ctrl+o` to return — it works across files.

---

## Editing & Refactoring

| Key | Action |
|-----|--------|
| `Space rn` | Rename symbol — updates all references in all files |
| `Space ca` | Code actions — quick fixes, auto-imports, etc. |
| `Space f` | Format file (also runs automatically on save) |

Format on save is active — `Space f` is only needed to force it manually.

---

## Completion (nvim-cmp)

Completions appear automatically in insert mode.

| Key | Action |
|-----|--------|
| `Tab` / `Shift+Tab` | Next / prev completion item |
| `Enter` | Confirm selection |
| `Ctrl+Space` | Force trigger completion |
| `Ctrl+e` | Dismiss popup |
| `Ctrl+b` / `Ctrl+f` | Scroll docs in popup up / down |

**Source priority:** LSP → snippets → buffer words → file paths.

---

## Snippets (luasnip + friendly-snippets)

Large snippet collection for most languages. Activated via completion.

| Key | Action |
|-----|--------|
| `Tab` | Expand snippet / jump to next field |
| `Shift+Tab` | Jump to previous field |

---

## Telescope LSP Pickers

| Key | Action |
|-----|--------|
| `Space ls` | All symbols in current file (functions, classes, vars) |
| `Space lw` | All symbols in workspace |
| `Space ld` | All diagnostics |

`Space ls` is the fastest way to navigate a large file.

---

## Practical Workflow

Replaces PyCharm's inspect / refactor panel:

1. Cursor on a symbol → `K` — read type and docs
2. `gd` — jump to definition; `Ctrl+o` — come back
3. `gr` — see all usages before renaming
4. `Space rn` — rename; all files updated atomically
5. `Space ca` on a red underline — pick the fix
6. `Space xx` — review all errors in the project at once
