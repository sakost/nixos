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

Servers: Python (pyright), Rust (rust-analyzer), **C/C++ (clangd + clangd-extensions)**, TypeScript (ts_ls), Nix (nil), Go (gopls), Lua, Bash, JSON, YAML, TOML, HTML, CSS, Protobuf (buf_ls)

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
| `Space e` | n | Show diagnostic float (in LSP buffers; toggles file explorer elsewhere) |
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

## CMake (cmake-tools.nvim)

Drives CMake projects end-to-end. On `:CMakeGenerate` it writes `build/<BuildType>/`
and symlinks `compile_commands.json` into the project root so clangd picks it up.
Errors land in the quickfix list (`:copen`).

| Key | Mode | Action |
|-----|------|--------|
| `Space cg` | n | **Generate** (`cmake -B build/<BuildType> -DCMAKE_EXPORT_COMPILE_COMMANDS=1`) |
| `Space cb` | n | **Build** current target |
| `Space cr` | n | **Run** launch target in a terminal split |
| `Space cd` | n | **Debug** launch target under nvim-dap (codelldb) |
| `Space cv` | n | Select build type (Debug / Release / RelWithDebInfo / MinSizeRel) |
| `Space ct` | n | Select build target |
| `Space cl` | n | Select launch target (the executable to run/debug) |
| `Space ck` | n | Stop running task |
| `Space cC` | n | Clean build directory |
| `Space ci` | n | Install |

Auto-regenerate on `CMakeLists.txt` save is enabled — edit and save, and the
build files update automatically.

### Typical workflow (C++ CMake project)

```
$ cd my-cmake-project   # directory with CMakeLists.txt
$ nvim .
```

Inside nvim:
1. `<Space>cg` — generate (first time only, or after changing CMake options)
2. `<Space>cv` — pick `Debug` so you get symbols for debugging
3. `<Space>ct` — select which target to build (if you have more than one)
4. `<Space>cl` — select which executable to launch (needed before `cr` / `cd`)
5. `<Space>cb` — build
6. `<Space>cr` — run it
7. `<Space>cd` — debug it (opens dap-ui, drops into the debugger at your breakpoints)

## Debugging (nvim-dap + dap-ui + dap-virtual-text)

Adapter: **codelldb** (same LLDB-based adapter for Rust **and** C/C++). Virtual
text shows live variable values next to each line. The dap-ui panels (scopes,
watches, stacks, breakpoints, repl) auto-open when a session starts and
auto-close when it ends.

### Step control (F-keys)

| Key | Mode | Action |
|-----|------|--------|
| `F5` | n | Continue / start session |
| `F10` | n | Step over |
| `F11` | n | Step into |
| `F12` | n | Step out |

### Leader commands (`Space D*` — capital D to avoid dadbod's `Space d*`)

| Key | Mode | Action |
|-----|------|--------|
| `Space Db` | n | Toggle breakpoint |
| `Space DB` | n | Conditional breakpoint (prompts for expression) |
| `Space Dl` | n | Log point (prints to REPL instead of stopping) |
| `Space Dc` | n | Continue (same as F5) |
| `Space Dr` | n | Toggle REPL |
| `Space DL` | n | Run last configuration |
| `Space Dt` | n | Terminate session |
| `Space Du` | n | Toggle dap-ui panels |
| `Space Dk` | n | Inspect value under cursor (floating hover) |
| `Space Dp` | n | Preview expression in split |

### Launch configurations

Defined in `home/programs/nixvim/dap.nix`:

- **`cpp` / `c`** — prompts for an executable path, defaulting to `./build/`
- **`rust`** — prompts for an executable path, defaulting to `target/debug/<crate-name>`
  (uses the current directory name as the crate name)

All three use codelldb with `sourceLanguages = ["rust"]` on the rust config so
LLDB formats `Vec<T>`, `String`, `Option<T>`, etc. correctly.

### Typical workflow (Rust binary)

```
$ cd my-rust-project
$ cargo build              # produces target/debug/my-rust-project
$ nvim src/main.rs
```

Inside nvim:
1. Click on a line → `<Space>Db` to set a breakpoint
2. `<F5>` → nvim-dap prompts `Path to executable:` with `target/debug/my-rust-project` pre-filled → hit Enter
3. dap-ui opens; execution stops at your breakpoint
4. Use `<F10>` / `<F11>` / `<F12>` to step around
5. Hover any variable with `<Space>Dk` to inspect its value
6. `<Space>Dt` to terminate

### Typical workflow (C++ via CMake)

1. Set breakpoints with `<Space>Db`
2. `<Space>cd` — cmake-tools picks up the selected launch target and hands it
   to nvim-dap with codelldb — no manual path entry needed
3. Step/inspect as above

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

## Database (vim-dadbod)

Built-in database client with UI sidebar. Supports PostgreSQL, MySQL, SQLite, and more.

### Keymaps

| Key | Mode | Action |
|-----|------|--------|
| `Space db` | n | Toggle DB UI sidebar |
| `Space df` | n | Find DB UI buffer |
| `Space dl` | n | Last query info |

### DB UI Sidebar

| Key | Context | Action |
|-----|---------|--------|
| `A` | sidebar | Add new connection |
| `d` | sidebar | Delete connection |
| `R` | sidebar | Rename connection |
| `<CR>` | sidebar | Expand/collapse or open table |
| `S` | table | Generate `SELECT *` query |
| `o` | sidebar | Open query buffer |

### Query Buffer

| Key | Context | Action |
|-----|---------|--------|
| `<leader>S` | sql buffer | Execute query (dadbod-ui default) |

SQL buffers get autocompletion for table/column names via nvim-cmp.

### Connection URLs

```
postgresql://user:pass@host:5432/dbname
mysql://user:pass@host:3306/dbname
sqlite:path/to/db.sqlite
```

For Cloud SQL via proxy: start `cloud-sql-proxy` first, then connect to `postgresql://user:pass@127.0.0.1:5432/dbname`.

## Terminal (snacks.nvim)

| Key | Mode | Action |
|-----|------|--------|
| `Ctrl+/` | n | Toggle bottom terminal |
| `Ctrl+/` | t | Hide terminal (from inside) |

Terminal persists across toggles — shell session stays alive.

## Markdown

| Key / Command | Mode | Action |
|---------------|------|--------|
| `Space mp` | n | Preview in Chrome |
| `:Pandoc html` | n | Convert to HTML (output next to source) |
| `:Pandoc pdf` | n | Convert to PDF (via XeLaTeX, supports Russian) |
| `:Pandoc docx` | n | Convert to DOCX |

`:Pandoc <format>` is available only in markdown buffers. Output file is placed next to the source with the new extension.

## Tips

- Press `Space` and wait ~200ms for **which-key** popup showing all bindings
- Colorscheme: **Tokyo Night** (transparent)
- Treesitter provides syntax highlighting for: bash, c, cpp, css, dockerfile, go, html, javascript, json, lua, markdown, markdown_inline, nix, proto, python, rust, toml, tsx, typescript, vim, vimdoc, yaml
