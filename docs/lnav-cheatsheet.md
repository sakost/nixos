# lnav Cheatsheet

Log file navigator — interactive viewer for log files with filtering, searching, SQL queries, and pretty-printing.

Config: `home/programs/lnav.nix`

## Opening logs

```bash
lnav /var/log/syslog              # Open a specific log file
lnav /var/log/                    # Open all log files in a directory
lnav -r                           # Recursively load rotated log files
journalctl -o json | lnav         # Pipe journald output
journalctl -b -o json | lnav     # Current boot logs via pipe
lnav -e "SELECT * FROM syslog_log WHERE log_level = 'error'"  # Run SQL on startup
```

## Navigation

| Key | Action |
|-----|--------|
| `g` / `G` | Jump to top / bottom |
| `e` / `E` | Next / previous error |
| `w` / `W` | Next / previous warning |
| `Space` / `Backspace` | Page down / up |
| `f` / `b` | Forward / backward one screen |
| `l` / `L` | Next / previous file |
| `>` / `<` | Scroll right / left (long lines) |
| `0` | Move to start of line |

## Searching & filtering

| Key | Action |
|-----|--------|
| `/pattern` | Search forward (regex) |
| `?pattern` | Search backward (regex) |
| `n` / `N` | Next / previous match |
| `:filter-in <regex>` | Show only matching lines |
| `:filter-out <regex>` | Hide matching lines |
| `:reset-session` | Clear all filters |
| `TAB` | Toggle filter panel visibility |
| `i` | Toggle histogram view |

## Views

| Key | Action |
|-----|--------|
| `t` | Toggle text-wrap |
| `T` | Display elapsed time between lines |
| `i` | Toggle histogram view (message frequency) |
| `I` | Toggle histogram by log level |
| `p` | Toggle pretty-print (JSON, XML) |
| `ENTER` | Toggle detail overlay for current line |
| `Shift+P` | Show parser details |
| `v` | Switch to SQL result view (after query) |

## SQL queries (`;` to open prompt)

```sql
;SELECT * FROM all_logs WHERE log_level = 'error'
;SELECT log_hostname, count(*) FROM syslog_log GROUP BY log_hostname
;SELECT * FROM all_logs WHERE log_body LIKE '%OOM%'
;SELECT log_time, log_level, log_body FROM all_logs WHERE log_time > datetime('now', '-1 hour')
```

| Command | Action |
|---------|--------|
| `;` | Open SQL prompt |
| `v` | View SQL results as table |
| `q` | Return from result view |

## Command mode (`:` to open prompt)

| Command | Action |
|---------|--------|
| `:open <path>` | Open another log file |
| `:close` | Close current file |
| `:goto <line/timestamp>` | Jump to line or timestamp |
| `:highlight <regex>` | Highlight matches with color |
| `:clear-highlight <regex>` | Remove highlight |
| `:set-min-log-level warning` | Hide messages below level |
| `:write-to <file>` | Write current view to file |
| `:save-session` | Save current session (filters, etc.) |
| `:comment <text>` | Add a comment to current line |

## Useful tips

- lnav auto-detects log formats (syslog, nginx, apache, JSON, etc.)
- Multiple files are merged chronologically
- Use `TAB` to see/manage active filters
- `Ctrl+R` to reset session (clear filters, highlights)
- `q` to quit or return from sub-views
