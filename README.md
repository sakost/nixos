# NixOS Configuration

Multi-host NixOS flake configuration with Hyprland, Nvidia, and sing-box proxy.

## Hosts

- **sakost-pc**: Main PC with 2x NVMe, LUKS encryption, TPM auto-unlock, Secure Boot

## Structure

```
├── flake.nix                 # Flake entry point
├── hosts/                    # Per-host configurations
│   └── sakost-pc/            # Main PC (LUKS + TPM + Secure Boot)
├── modules/                  # Shared NixOS modules
│   ├── hardware/             # GPU, CPU, audio, bluetooth, TPM
│   ├── desktop/              # Hyprland, greetd, XDG portals
│   ├── programs/             # zsh, fonts, git, nix-ld
│   └── services/             # SSH, networking, proxy
├── lib/                      # Shared Nix libraries
│   └── theme.nix             # Centralized theme (colors, fonts, opacity)
├── home/                     # Home-manager configuration
│   ├── sakost.nix            # User entry point
│   ├── xdg.nix              # XDG dirs, env vars, cache paths
│   ├── programs/             # User programs (nixvim, zsh, waybar, etc.)
│   └── desktop/              # Hyprland user config
└── secrets/                  # SOPS-encrypted secrets
```

## Quick Start

### 1. Clone and Setup

```bash
cd ~
git clone <repo-url> nixos-config
cd nixos-config
```

### 2. Setup SOPS Secrets

**sakost-pc** uses the SSH host key for age decryption (available before `/home` mounts):
```bash
# The age key is derived from /etc/ssh/ssh_host_ed25519_key
# Add the host's age public key to .sops.yaml
```

A user-level age key (`~/.config/sops/age/keys.txt`) is also recognized for editing secrets without root access.

Then create and encrypt the sing-box config:
```bash
nvim secrets/sing-box.json   # Create with your credentials
sops -e -i secrets/sing-box.json
```

### 3. Build and Switch

```bash
sudo nixos-rebuild switch --flake .#sakost-pc
```

## Features

### Hardware
- Nvidia GPU with proprietary drivers
- Intel/AMD CPU microcode updates
- PipeWire audio (low-latency)
- Bluetooth support
- TPM 2.0 with systemd-initrd auto-unlock (sakost-pc)

### Desktop
- Hyprland Wayland compositor with HDR (4K@144Hz on DP-2, 1080p@60 on HDMI-A-1)
- Waybar status bar (per-monitor clock formats, media player, glassmorphic pills)
- Eww dashboard overlay (clock, weather, system stats, media player with album art, calendar, news)
- greetd display manager with ReGreet (GTK4 graphical greeter)
- hyprlock lock screen (screenshot blur, keyboard layout, power status)
- SwayNC notification center (notification history, DND toggle, MPRIS media)
- Plymouth boot splash (catppuccin-mocha theme, silent boot)
- swww wallpaper daemon with wallpaper picker (`Super+W`)
- Walker launcher (apps, clipboard, files, windows, calculator, custom quicklinks)
- Bluetooth manager (`Super+B`) and monitor management (`Super+M`)
- Volume/brightness OSD (eww, follows focused monitor, DDC/CI for external displays)
- USB device notification popup (auto-detect type with icons)
- Cava audio visualizer (TokyoNight gradient)
- Telegram Desktop (autostart minimized to tray)

### Programs
- **Editors**: Nixvim with full IDE setup (LSPs, completion, telescope, git integration)
- **Shells**: Zsh with starship prompt, atuin history, autosuggestions, syntax highlighting
- **Terminal**: Alacritty (50k scrollback)
- **Launcher**: Walker (Wayland-native, built-in clipboard/files/windows/calculator)
- **File manager**: Nautilus (GUI), yazi (terminal)
- **Browsers**: Google Chrome
- **Dev tools**: rustup (stable), Go, Node.js, npm, Yarn, uv, ripgrep, direnv + nix-direnv
- **CLI tools**: Claude Code, eza, bat, fd, fzf, zoxide, atuin, tldr, fastfetch
- **GUI apps**: Telegram Desktop, Google Chrome
- **Compatibility**: nix-ld for running unpatched binaries

### Theme

TokyoNight dark theme defined in `lib/theme.nix` and shared across all components (alacritty, waybar, swaync, eww, wlogout, hyprlock, walker, starship, fzf, zathura, yazi, hyprland, greetd, cava, plymouth). All colors, fonts, opacity, and border values are centralized — edit one file to retheme everything.

### Services
- OpenSSH (key-only auth)
- sing-box proxy with VLESS Reality (TUN mode)
- NetworkManager

### XDG & Cache
- Full XDG Base Directory compliance
- Package manager caches centralized to `~/dev/cache/<name>` (npm, yarn, uv, pip, cargo, go, cuda)

## Secrets Management

Uses SOPS with age encryption. Keys are derived from the SSH host key (sakost-pc) plus a user age key for local secret editing.

**Files:**
- `.sops.yaml` - SOPS configuration with public keys
- `secrets/sing-box.json` - Encrypted sing-box config

### Editing Secrets

```bash
sops secrets/sing-box.json        # Auto-decrypt/encrypt
sops -d secrets/sing-box.json     # Decrypt to view
```

## Adding a New Host

1. Create `hosts/<hostname>/` with `default.nix`, `hardware.nix`, `disk-config.nix`
2. Add to `flake.nix`:
   ```nix
   nixosConfigurations.<hostname> = mkHost "<hostname>";
   ```
3. Update `.sops.yaml` with the host's age public key

## Useful Commands

```bash
# Rebuild aliases (defined in home/programs/zsh.nix)
nrs   # nixos-rebuild switch --flake ~/nixos-config
nrb   # nixos-rebuild build --flake ~/nixos-config
nrt   # nixos-rebuild test --flake ~/nixos-config

# Edit config
ne    # nvim ~/nixos-config

# Flake operations
nix flake check
nix flake update

# Garbage collection
sudo nix-collect-garbage -d
```

## Nixvim Keybindings

| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<leader>e` | Toggle file explorer |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fb` | Find buffers |
| `<leader>gg` | Open LazyGit |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |

## Inspiration

Desktop rice (eww dashboard, USB popup, scripts, swaync styling) inspired by [ilyamiro's NixOS config](https://github.com/ilyamiro/nixos-configuration).

## License

Personal configuration - use at your own risk.
