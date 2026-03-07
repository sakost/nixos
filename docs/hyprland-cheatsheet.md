# Hyprland Cheatsheet

Mod key: **Super** (Windows key)

## Apps & Session

| Key | Action |
|-----|--------|
| `Super + Q` | Open terminal (Alacritty) |
| `Super + Space` | App launcher (Walker) |
| `Super + E` | File manager (Nautilus) |
| `Super + D` | Lock screen (hyprlock) |
| `Super + Escape` | Power menu (wlogout) |
| `Power Button` | Power menu (wlogout) |
| `Super + M` | Monitor management (resolution/refresh rate) |
| `Super + W` | Wallpaper picker (swww) |
| `Super + B` | Bluetooth manager |
| `Super + F1` | Open cheatsheet (this file!) |

## Windows

| Key | Action |
|-----|--------|
| `Super + C` | Close active window |
| `Super + Shift + C` | Force-kill (click to pick window) |
| `Super + Ctrl + C` | Hide window to hidden workspace |
| `Super + Ctrl + V` | Toggle hidden workspace |
| `Super + F` | Toggle floating mode |
| `Super + P` | Toggle pseudo-tiling |
| `Super + J` | Toggle split direction (dwindle) |

## Focus

| Key | Action |
|-----|--------|
| `Super + Left` | Focus left |
| `Super + Right` | Focus right |
| `Super + Up` | Focus up |
| `Super + Down` | Focus down |

## Resize (Keyboard)

| Key | Action |
|-----|--------|
| `Super + Shift + Left` | Shrink width |
| `Super + Shift + Right` | Grow width |
| `Super + Shift + Up` | Shrink height |
| `Super + Shift + Down` | Grow height |

## Move / Resize (Mouse)

| Key | Action |
|-----|--------|
| `Super + Left Click` + drag | Move window |
| `Super + Right Click` + drag | Resize window |

## Workspaces

Each monitor has its own independent set of workspaces (1-10) via hyprsplit.
Switching workspaces syncs all monitors to the same workspace number.

| Key | Action |
|-----|--------|
| `Super + 1-9, 0` | Switch all monitors to workspace 1-10 |
| `Super + Shift + 1-9, 0` | Move window to workspace 1-10 (focused monitor) |
| `Super + Ctrl + Right` | Next workspace (synced across monitors) |
| `Super + Ctrl + Left` | Previous workspace (synced across monitors) |
| `Super + Mouse Scroll` | Cycle workspaces (synced across monitors) |

## Special Workspace (Scratchpad)

| Key | Action |
|-----|--------|
| `Super + S` | Toggle scratchpad |
| `Super + Shift + S` | Move window to scratchpad |

## Walker Providers

| Key | Action |
|-----|--------|
| `Super + Space` | App launcher |
| `Super + TAB` | Window switcher |
| `Super + V` | Clipboard history |
| `Super + T` | File browser |

## Notifications (SwayNC)

| Key | Action |
|-----|--------|
| `Super + N` | Toggle notification center |
| `Super + Shift + N` | Toggle Do Not Disturb |

## Screenshot

| Key | Action |
|-----|--------|
| `Print` | Select region, copy to clipboard |
| `Shift + Print` | Select region, edit in Satty |
| `Super + Print` | Select region, save to ~/Pictures |

## Volume & Brightness

| Key | Action |
|-----|--------|
| `Volume Up/Down` | Adjust volume (eww OSD on focused monitor) |
| `Mute` | Toggle mute (speaker) |
| `Mic Mute` | Toggle mute (microphone) |
| `Brightness Up/Down` | Adjust brightness (DDC/CI via ddcutil) |

## Media

| Key | Action |
|-----|--------|
| `Play/Pause` | Toggle playback |
| `Next` | Next track |
| `Previous` | Previous track |

## Keyboard Layout

| Key | Action |
|-----|--------|
| `Right Alt` | Toggle US / RU layout (via XKB) |

## Wlogout Keys (inside power menu)

| Key | Action |
|-----|--------|
| `L` | Logout |
| `U` | Suspend |
| `R` | Reboot |
| `S` | Shutdown |

## Plugins

- **hyprsplit**: Per-monitor workspace sets with synchronized switching
- **hyprwinwrap**: Use any window as desktop wallpaper

## Layout Info

- Layout: **dwindle** (binary split)
- Gaps: 4px inner, 8px outer
- Border: 2px, accent-to-magenta gradient (active), translucent (inactive)
- Active window shadow with accent glow
- Inactive windows at 95% opacity
