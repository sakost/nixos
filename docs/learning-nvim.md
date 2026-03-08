# Learning Neovim — Power User Guide

Progressive reference for going deeper than basic modal editing.
For keybindings specific to this config, see `nvim-cheatsheet.md`.

---

## The Grammar: `[operator][count][motion/text-object]`

Every editing command is a sentence. Operators, counts, and motions compose freely.

```
d  w      → delete word
c  i  "   → change inside quotes
y  3  j   → yank 3 lines down
>  i  {   → indent inside braces
gc i  {   → comment out block
```

### Operators

| Key | Action |
|-----|--------|
| `d` | Delete (into register) |
| `c` | Change (delete + enter insert mode) |
| `y` | Yank (copy) |
| `>` / `<` | Indent / unindent |
| `=` | Auto-indent |
| `gc` | Toggle comment (vim-commentary) |

### Text Objects

Combine with any operator. `i` = inner (excluding delimiters), `a` = around (including).

| Text object | Selects |
|-------------|---------|
| `iw` / `aw` | word / word + surrounding space |
| `i"` / `a"` | inside quotes / including quotes |
| `i'` / `a'` | inside single quotes / including |
| `i(` / `a(` | inside parens / including parens |
| `i{` / `a{` | inside braces / including braces |
| `i[` / `a[` | inside brackets / including |
| `ip` / `ap` | paragraph |
| `it` / `at` | HTML/XML tag contents / whole tag |

**Practical examples:**

```
ci"     → clear string and start typing (change inside quotes)
da(     → delete entire function call including parens
yip     → copy whole paragraph
=i{     → auto-indent everything inside current braces
gci{    → comment out entire block
```

---

## Counts

Any operator or motion accepts a count prefix:

```
3dd     → delete 3 lines
5j      → move down 5 lines
2cw     → change 2 words
d3w     → delete 3 words forward
```

---

## Dot Repeat — `.`

Repeats your last change exactly. The most underused key.

```
ciwnewword<jk>  → change a word to "newword"
w.              → move to next word, apply the same change
```

Replaces macros for simple repetitive edits.

---

## Navigation (deeper)

| Key | Movement |
|-----|----------|
| `w` / `b` | Next / prev word start |
| `e` | Next word end |
| `W` / `B` / `E` | Same but WORD (space-delimited) |
| `f{c}` | Jump to next character `c` on line |
| `F{c}` | Jump to prev character `c` on line |
| `t{c}` / `T{c}` | Jump before / after character |
| `;` / `,` | Repeat `f/t` forward / backward |
| `%` | Jump to matching bracket |
| `{` / `}` | Jump between blank lines (paragraphs) |
| `Ctrl+d` / `Ctrl+u` | Half page down / up |
| `zz` | Center screen on cursor |
| `zt` / `zb` | Move cursor to top / bottom of screen |

---

## Jumps & Marks

| Key | Action |
|-----|--------|
| `Ctrl+o` | Jump back to previous location |
| `Ctrl+i` | Jump forward |
| `ma` | Set mark `a` at cursor |
| `` `a `` | Jump to exact position of mark `a` |
| `'a` | Jump to line of mark `a` |
| `''` | Jump back to last jump origin |

After `gd` (go to definition), `Ctrl+o` brings you right back.

---

## Visual Mode — 3 Flavors

| Key | Mode |
|-----|------|
| `v` | Character-wise |
| `V` | Line-wise |
| `Ctrl+v` | Block (column editing) |

**Block visual for column edits:**
```
Ctrl+v → select column of lines → I → type → Esc
```
Inserts text at the start of every selected line simultaneously.

Once in visual mode, all operators apply to the selection:
`d`, `y`, `c`, `>`, `<`, `=`, `gc`

---

## nvim-surround (installed)

| Key | Action | Example |
|-----|--------|---------|
| `ys[motion][char]` | Add surround | `ysiw"` → wrap word in `"` |
| `cs[old][new]` | Change surround | `cs"'` → `"word"` → `'word'` |
| `ds[char]` | Delete surround | `ds"` → `"word"` → `word` |
| `yss[char]` | Surround whole line | `yss"` |

```
ysiw(   → word → (word)
cs({    → (word) → {word}
dst     → delete surrounding HTML tag
```

---

## Search & Replace

```
/pattern        → search forward  (n = next, N = prev)
?pattern        → search backward
*               → search word under cursor (forward)
#               → search word under cursor (backward)
:%s/old/new/g   → replace all in file
:%s/old/new/gc  → replace all with confirmation
:s/old/new/g    → replace in current line only
```

With a visual selection active, `:s` scopes to the selection automatically.

---

## Registers (multiple clipboards)

| Register | Contents |
|----------|----------|
| `"` | Default — last yank or delete |
| `0` | Last **yank only** (survives deletes) |
| `+` | System clipboard |
| `a`–`z` | Named — set manually |

```
"ayiw   → yank word into register a
"ap     → paste from register a
"0p     → paste last yank (even after a delete)
:reg    → inspect all register contents
```

> **Common gotcha:** delete something, then try to paste your earlier copy — the
> delete overwrote `"`. Use `"0p` to paste the last *yank* instead.

---

## Macros

Record a sequence of commands and replay it.

```
qa      → start recording into register a
...     → do stuff
q       → stop recording
@a      → replay macro a
@@      → replay last macro
10@a    → replay 10 times
```

Example — add semicolon to end of 5 lines:
```
qa A;<jk> j q   → record: append semicolon, move down
4@a             → repeat 4 more times
```

---

## Windows & Splits

| Key | Action |
|-----|--------|
| `:sp` / `:vsp` | Horizontal / vertical split |
| `Ctrl+h/j/k/l` | Move between windows (config binding) |
| `Ctrl+↑/↓/←/→` | Resize window (config binding) |
| `:only` | Close all splits except current |
| `ZZ` | Save and close current window |

---

## Command Line Tips

```
:earlier 5m     → undo to state 5 minutes ago
:later 1m       → redo forward 1 minute
:!cmd           → run shell command
:r !cmd         → insert shell command output at cursor
:%!jq .         → pipe entire file through jq (format JSON)
:g/pattern/d    → delete all lines matching pattern
:v/pattern/d    → delete all lines NOT matching pattern
```
