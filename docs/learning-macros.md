# Macros — Recorded Automation

Macros record any sequence of keystrokes and replay them.
Write the automation by just doing the thing once.

---

## Record & Replay

```
qa       → start recording into register 'a'
... do stuff in normal / insert / visual mode ...
q        → stop recording
@a       → replay macro 'a'
@@       → replay last used macro
10@a     → replay 10 times
```

Any letter `a–z` works as a register. `q` stops recording (same key as start).

---

## The Mental Model

A macro captures exactly what you type — every motion, every keypress, every
mode switch. For reliable replay:

- Use **repeatable motions** (`w`, `$`, `f{char}`) not arrow keys
- End on a **predictable position** for the next iteration (usually `j`)

---

## Practical Example — append semicolons to lines

```
qa          → start recording into 'a'
A;<jk>      → append semicolon, exit insert mode
j           → move to next line
q           → stop recording
@a          → replay on next line
9@@         → replay 9 more times (10 lines total)
```

---

## Executing on a Range

```
:5,15norm @a      → run macro on lines 5–15
:'<,'>norm @a     → run on visual selection
:%norm @a         → run on every line in the file
```

`norm` executes normal-mode commands on each line in the range.

---

## Editing a Macro

Macros live in registers — edit them like text:

```
"ap        → paste macro 'a' contents as text
... edit ...
"ayy       → yank the line back into register 'a'
```

---

## Recursive Macros

A macro can call itself to loop until it hits an error (e.g. end of file):

```
qb         → start recording into 'b'
... do stuff ...
@b         → call itself
q          → stop recording
@b         → run — loops until something fails
```

Use `Ctrl+C` to interrupt if it runs away.

---

## Tips

| Technique | When to use |
|-----------|-------------|
| `.` dot repeat | Single-operation repetition |
| Macro | Multi-step repetition across lines |
| `n.` pattern | Search `/pattern`, then `n` to next match, `.` to apply change |
| `"1`–`"9` registers | Last 9 deletions stored automatically — no recording needed |
