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

| Key | Action |
|-----|--------|
| `Super + 1-9, 0` | Switch to workspace 1-10 |
| `Super + Shift + 1-9, 0` | Move window to workspace 1-10 |
| `Super + Mouse Scroll` | Cycle through workspaces |

## Virtual Desktops

| Key | Action |
|-----|--------|
| `Super + Ctrl + Right` | Next virtual desktop |
| `Super + Ctrl + Left` | Previous virtual desktop |

All monitors switch together when changing virtual desktops.

## Overview

| Key | Action |
|-----|--------|
| `Super + TAB` | Toggle Hyprspace overview panel |

## Special Workspace (Scratchpad)

| Key | Action |
|-----|--------|
| `Super + S` | Toggle scratchpad |
| `Super + Shift + S` | Move window to scratchpad |

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

- **virtual-desktops**: All monitors switch as one unified desktop
- **Hyprspace**: Workspace overview panel with thumbnails
- **hyprwinwrap**: Use any window as desktop wallpaper

## Layout Info

- Layout: **dwindle** (binary split)
- Gaps: 5px inner, 20px outer
- Border: 2px, cyan-to-green gradient (active), grey (inactive)
- Rounding: 10px
- New splits open right/below
