# Terminal Tools Cheatsheet

Modern CLI tools configured in `home/programs/`. Theme: TokyoNight dark.

## eza (ls replacement)

Config: `home/programs/zsh.nix` (programs.eza)

| Alias | Command | Description |
|-------|---------|-------------|
| `l` | `eza -l` | Long listing |
| `ll` | `eza -la` | Long listing with hidden files |
| `la` | `eza -a` | All files (short) |
| `lt` | `eza --tree --level=2` | Tree view (2 levels deep) |

Icons and git status shown automatically. Directories listed first.

## bat (cat replacement)

Config: `home/programs/zsh.nix` (programs.bat)

| Alias | Description |
|-------|-------------|
| `cat` | Aliased to `bat` |

```bash
bat file.nix                  # Syntax-highlighted file view
bat -l nix file               # Force language (when extension is missing)
bat --diff file.nix            # Show git diff inline
bat -p file.nix               # Plain mode (no line numbers/header)
bat -r 10:20 file.nix         # Show only lines 10-20
bat file1 file2               # Concatenate multiple files
command cat file               # Use real cat when needed
```

Theme: `tokyonight_night`

## starship (prompt)

Config: `home/programs/starship.nix`

Prompt shows: **directory** → **git branch/status** → **nix-shell** → **language** → **newline** → **❯**

- Green `❯` on success, red `❯` on error
- Directory truncated to 3 levels (to repo root)
- Language indicators appear automatically: Rust, Go, Python, Node.js
- Nix shell indicator appears inside `nix develop` / `nix-shell`

To temporarily show kubernetes context:

```bash
STARSHIP_KUBERNETES_DISABLED=false starship prompt
# Or edit home/programs/starship.nix: kubernetes.disabled = false
```

## atuin (shell history)

Config: `home/programs/atuin.nix`

| Key | Action |
|-----|--------|
| `Up` | Search history (current session) |
| `Ctrl + R` | Full history search |

- Search mode: **fuzzy** (type fragments in any order)
- Up-arrow scoped to current session by default
- `Ctrl + R` searches all sessions
- Style: compact (single-line entries)
- Sync: disabled (local only)

```bash
atuin search "git push"       # Search from command line
atuin stats                   # Usage statistics
```

## fzf (fuzzy finder)

Config: `home/programs/zsh.nix` (programs.fzf)

| Key | Action |
|-----|--------|
| `Ctrl + T` | Fuzzy find file (insert path) + bat syntax preview |
| `Ctrl + R` | Fuzzy history search (overridden by atuin) |
| `Alt + C` | Fuzzy cd into directory + eza tree preview |

Uses `fd` as backend (respects `.gitignore`, includes hidden files, excludes `.git/`).

## fd (find replacement)

```bash
fd pattern                    # Find files matching pattern
fd -e nix                     # Find by extension
fd -t d src                   # Find directories only
fd -t f -e rs                 # Find files by extension
fd -H pattern                 # Include hidden files
fd pattern /path              # Search in specific directory
```

## yazi (file manager)

Config: `home/programs/yazi.nix`

Launch with `y` (shell wrapper — `cd`s to last directory on exit).

| Key | Action |
|-----|--------|
| `h` / `l` | Parent / enter directory |
| `j` / `k` | Move down / up |
| `Enter` | Open file |
| `Space` | Select file |
| `d` | Trash selected |
| `D` | Permanently delete |
| `y` | Yank (copy) |
| `x` | Cut |
| `p` | Paste |
| `r` | Rename |
| `.` | Toggle hidden files |
| `z` | Jump with zoxide |
| `/` | Search in directory |
| `q` | Quit |
| `~` | Go to home |
| `Tab` | Switch pane |

## zoxide (replaces cd)

Config: `home/programs/zsh.nix` (programs.zoxide)

Zoxide replaces `cd` directly — all commands below use `cd`/`cdi`:

```bash
cd foo                        # Smart jump to most-used directory matching "foo"
cd foo bar                    # Match multiple fragments
cdi foo                       # Interactive fzf selection + eza tree preview
cd -                          # Go back to previous directory
```

Learns from your `cd` usage — most visited directories rank higher.

## tldr (man replacement)

```bash
tldr tar                      # Quick examples for tar
tldr --update                 # Update local cache
tldr -l                       # List all available pages
```

Community-maintained cheat sheets with practical examples.

## direnv

Config: `home/sakost.nix` (programs.direnv)

Automatically loads/unloads environment when entering directories with `.envrc`:

```bash
echo "use flake" > .envrc     # Use flake's devShell
direnv allow                  # Approve the .envrc
# Environment loads automatically on cd
```
