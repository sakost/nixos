# Walker Cheatsheet

Wayland-native application launcher. Config: `home/programs/walker.nix`

Open with **Super + Space**

## Prefixes

| Prefix | Provider | Usage |
|--------|----------|-------|
| *(none)* | Applications | Type app name to launch |
| `=` | Calculator | Math expressions (`=2+2`, `=5kg to lb`) |
| `.` | Symbols | Unicode symbol search (`.arrow`) |
| `>` | Runner | Run shell command (`>ls -la`) |
| `@` | Web Search | Google search (`@nixos wayland`) |
| `:` | Clipboard | Browse clipboard history (`:paste`) |
| `/` | Files | Browse/search files (`/Documents`) |
| `$` | Windows | Switch windows (`$firefox`) |
| `;` | Provider List | Show all available providers |

## Keybindings (from Hyprland)

| Key | Action |
|-----|--------|
| `Super + Space` | Open app launcher |
| `Super + V` | Clipboard history |
| `Super + T` | File browser |
| `Super + TAB` | Window switcher |
| `Escape` | Close walker |
| `Enter` | Select highlighted result |
| `Up/Down` | Navigate results |

## Dmenu Mode

Walker supports dmenu-style piping:

```bash
echo -e "option1\noption2\noption3" | walker --dmenu
```

## Notes

- Walker runs as a systemd service for instant startup
- Clipboard monitoring is built-in (no separate cliphist service needed)
- Max 10 results shown at a time
- Theme: TokyoNight dark with semi-transparent background
- Requires `GSK_RENDERER=gl` on NVIDIA (set in Hyprland env)
