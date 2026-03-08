# Command Line Tips — `:` is a scripting language

Far more powerful than `:w` / `:q` / `:s`. Has ranges, filters, global
commands, and can pipe through shell tools.

---

## Ranges

Every `:` command accepts a range prefix:

```
:5,15d          → delete lines 5–15
:'<,'>          → visual selection (auto-inserted when typing : in visual)
:%              → whole file
:.              → current line
:.,+5           → current line plus next 5
:/foo/,/bar/    → from line matching "foo" to line matching "bar"
:'a,'b          → from mark a to mark b
```

---

## Global Command — `:g`

Run a command on every line matching a pattern. Think `grep | xargs`.

```
:g/pattern/d            → delete all matching lines
:g/pattern/y A          → yank all matching lines, append to register a
:g/TODO/norm A !!       → append " !!" to every TODO line
:v/pattern/d            → delete all NON-matching lines (v = inVert)
```

---

## Shell Integration

```
:!cmd               → run shell command, show output
:r !cmd             → insert command output at cursor
:%!cmd              → pipe entire file through command and replace
:.!cmd              → pipe current line through command and replace
```

**Examples:**

```
:%!jq .             → format JSON file through jq
:%!sort             → sort all lines
:.!date             → replace current line with today's date
:r !curl -s url     → insert URL response at cursor
```

---

## Undo Tree — `:earlier` / `:later`

Vim's undo is a **tree**, not a stack. You can never truly lose changes.

```
:earlier 5m         → revert to state 5 minutes ago
:earlier 10         → revert 10 changes back
:later 1m           → go forward 1 minute
:undolist           → show undo tree branches
```

Even after undoing and making new changes (new branch), old branches remain
accessible via `:undolist`.

---

## Useful One-liners

```
:sort               → sort lines
:sort!              → sort reverse
:sort u             → sort and remove duplicates
:g/^$/d             → delete all blank lines
:g/^\s*$/d          → delete blank or whitespace-only lines
:%s/\s\+$//         → strip trailing whitespace
:retab              → convert tabs ↔ spaces (per config)
```

---

## Multiple Files

```
:args *.py                          → set argument list to all Python files
:argdo %s/foo/bar/g | update        → replace in all of them
:bufdo %s/foo/bar/g | update        → replace in all open buffers
```

---

## Marks as Range

```
:'a,'b d                → delete from mark a to mark b
:'a,'b s/foo/bar/g      → replace in that region
```
