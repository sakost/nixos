# Telescope — Fuzzy Finding Everything

Universal picker with live preview. Not just files — searches almost anything.

---

## File & Text Search

| Key | Action |
|-----|--------|
| `Space ff` | Find files (filename search) |
| `Space fg` | Live grep — search text across all files |
| `Space fr` | Recent files |
| `Space fb` | Open buffers |
| `Space fh` | Help tags |

**Live grep (`Space fg`) tips:**
- Type to filter by content
- Append two spaces then a filename fragment to filter both: `myFunc  utils.py`
- Results update instantly as you type

---

## Git Pickers

| Key | Action |
|-----|--------|
| `Space gc` | Git commits — browse log with diff preview |
| `Space gs` | Git status — staged / unstaged files |

---

## LSP Pickers

| Key | Action |
|-----|--------|
| `Space ls` | Document symbols — functions, classes in current file |
| `Space lw` | Workspace symbols |
| `Space ld` | Diagnostics |

`Space ls` is the fastest way to jump to a function in a large file.

---

## Inside Telescope — Navigation

| Key | Action |
|-----|--------|
| `Ctrl+j` / `Ctrl+k` | Move down / up in results |
| `Enter` | Open selection |
| `Ctrl+v` | Open in vertical split |
| `Ctrl+s` | Open in horizontal split |
| `Ctrl+t` | Open in new tab |
| `Ctrl+u` / `Ctrl+d` | Scroll preview up / down |
| `Ctrl+q` | Send all results to quickfix list |
| `Esc` | Close Telescope |

---

## Quickfix — `Ctrl+q` from Telescope

Send all Telescope results to the quickfix list for batch operations.

```
:copen              → open quickfix window
]q / [q             → jump to next / prev quickfix item
:cdo s/old/new/g    → run a command on every quickfix item
```

**Project-wide search and replace:**
1. `Space fg` — search for the pattern
2. `Ctrl+q` — send all matches to quickfix
3. `:cdo s/old/new/g | update` — replace in every matched file
