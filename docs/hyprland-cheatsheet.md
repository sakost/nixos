# Hyprland Cheatsheet

Mod key: **Super** (Windows key)

## Apps

| Key | Action |
|-----|--------|
| `Super + Q` | Open terminal (Alacritty) |
| `Super + R` | App launcher (Rofi) |
| `Super + E` | File manager (Nautilus) |
| `Super + Escape` | Power menu (wlogout: logout/suspend/reboot/shutdown) |

## Windows

| Key | Action |
|-----|--------|
| `Super + C` | Close active window |
| `Super + F` | Toggle floating mode |
| `Super + V` | Clipboard history (Rofi) |
| `Super + P` | Toggle pseudo-tiling |
| `Super + J` | Toggle split direction (dwindle) |

## Focus

| Key | Action |
|-----|--------|
| `Super + Left` | Focus left |
| `Super + Right` | Focus right |
| `Super + Up` | Focus up |
| `Super + Down` | Focus down |

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
| `Super + Mouse Scroll` | Cycle workspaces (focused monitor only) |

## Special Workspace (Scratchpad)

| Key | Action |
|-----|--------|
| `Super + S` | Toggle scratchpad |
| `Super + Shift + S` | Move window to scratchpad |

## Overview

| Key | Action |
|-----|--------|
| `Super + TAB` | Toggle Hyprspace overview panel |

## Screenshot

| Key | Action |
|-----|--------|
| `Print` | Select region, copy to clipboard |
| `Shift + Print` | Select region, edit in Satty |
| `Super + Print` | Select region, save to ~/Pictures |

## Keyboard Layout

| Key | Action |
|-----|--------|
| `Right Alt` | Toggle US / RU layout |

## Volume

| Key | Action |
|-----|--------|
| `Volume Up` | +5% |
| `Volume Down` | -5% |
| `Mute` | Toggle mute (speaker) |
| `Mic Mute` | Toggle mute (microphone) |

## Media

| Key | Action |
|-----|--------|
| `Play/Pause` | Toggle playback |
| `Next` | Next track |
| `Previous` | Previous track |

## Wlogout Keys (inside power menu)

| Key | Action |
|-----|--------|
| `L` | Logout |
| `U` | Suspend |
| `R` | Reboot |
| `S` | Shutdown |

## Plugins

- **hyprsplit**: Per-monitor workspace sets with synchronized switching
- **Hyprspace**: Workspace overview panel with thumbnails (currently disabled)
- **hyprwinwrap**: Use any window as desktop wallpaper

## Layout Info

- Layout: **dwindle** (binary split)
- Gaps: 5px inner, 20px outer
- Border: 2px, cyan-to-green gradient (active), grey (inactive)
- Rounding: 10px
- New splits open right/below
