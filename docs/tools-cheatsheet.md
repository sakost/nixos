# Desktop Tools Cheatsheet

## Wallpaper Picker (`Super + W`)

1. Press `Super + W` to launch
2. Browse wallpapers from `~/Pictures/wallpapers/` (images, GIFs, videos)
3. Select a file
4. Choose target: specific monitor or "All monitors"
5. Static images/GIFs: applied with swww grow transition
6. Videos: played via mpvpaper (looped, no audio)

**Setup:** Add files to `~/Pictures/wallpapers/` (up to 2 levels deep).

**Supported formats:** PNG, JPG, JPEG, WebP, GIF, MP4, WebM, MKV

**Notes:**
- GIFs are animated natively by swww
- Videos loop infinitely with no audio via mpvpaper
- Selecting a new video wallpaper kills any existing mpvpaper instances

## Bluetooth Manager (`Super + B`)

1. Press `Super + B` to launch
2. If bluetooth is off, select "Power On"
3. Menu shows:
   - Paired devices (with `[connected]` status)
   - "Scan for devices" — scans for 10 seconds
   - "Power Off"
4. Select a device to toggle connection

## Monitor Manager (`Super + M`)

1. Press `Super + M` to launch
2. If multiple monitors, pick which one
3. Select resolution (3840x2160 down to 1280x720)
4. Select refresh rate (240Hz down to 30Hz)
5. Applied immediately (preserves current position and scale)

**Note:** Changes are temporary (until next reboot). Edit `home/desktop/hyprland/default.nix` for permanent changes.

## Cheatsheet Viewer (`Super + F1`)

1. Press `Super + F1`
2. Select a cheatsheet from the list
3. Opens in a floating terminal rendered with glow

## Notification Center (`Super + N`)

| Key | Action |
|-----|--------|
| `Super + N` | Toggle notification center sidebar |
| `Super + Shift + N` | Toggle Do Not Disturb |

The notification center shows:
- All notification history
- DND toggle switch
- MPRIS media player controls

## Volume / Brightness OSD

OSD popups appear on the **focused monitor**.

| Key | Action |
|-----|--------|
| Volume Up/Down | Adjust volume (+/- 5%) |
| Mute | Toggle speaker mute |
| Mic Mute | Toggle microphone mute |
| Brightness Up/Down | Adjust brightness (+/- 5% via DDC/CI) |

## Eww Dashboard

The dashboard is always visible on HDMI-A-1 (rendered behind windows).

**Widgets:** Clock, greeting, weather (Moscow), system stats (CPU/RAM/disk/GPU/network), media player with album art, power buttons, calendar (gcalcli), Hacker News feed, notification status.

**Power buttons:** Lock, Logout, Reboot, Shutdown

## Walker Quick Commands

Type `!` followed by a keyword in the app launcher:

| Command | Action |
|---------|--------|
| `!gh <query>` | Search GitHub |
| `!gl <query>` | Search GitLab |
| `!nix <query>` | Search NixOS packages |
| `!hm <query>` | Search Home Manager options |
| `!wiki <query>` | Search NixOS Wiki |
| `!yt <query>` | Search YouTube |

## USB Notifications

Automatic popup when USB devices are plugged in:
- Detects device type (storage, keyboard, mouse, audio, camera)
- Shows vendor/model info
- Storage devices show capacity
- Auto-dismisses after 5 seconds
