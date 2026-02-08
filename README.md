# NixOS Configuration

Multi-host NixOS flake configuration with Hyprland, Nvidia, and sing-box proxy.

## Hosts

- **sakost-pc**: Main PC with 2x NVMe, LUKS encryption, TPM auto-unlock, Secure Boot
- **sakost-pc-portable**: Portable/temp disk setup

## Structure

```
├── flake.nix                 # Flake entry point
├── hosts/                    # Per-host configurations
│   ├── sakost-pc/            # Main PC (LUKS + TPM + Secure Boot)
│   └── sakost-pc-portable/   # Portable host
├── modules/                  # Shared NixOS modules
│   ├── hardware/             # GPU, CPU, audio, bluetooth, TPM
│   ├── desktop/              # Hyprland, greetd, XDG portals
│   ├── programs/             # zsh, fonts, git, nix-ld
│   └── services/             # SSH, networking, proxy
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

**sakost-pc-portable** uses a user age key:
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Add your public key to .sops.yaml
```

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
- Hyprland Wayland compositor with HDR (4K@144Hz)
- Waybar status bar with calendar tooltip
- greetd display manager with tuigreet
- XDG desktop portals
- swww wallpaper daemon
- cliphist clipboard manager
- Telegram Desktop (autostart minimized to tray)

### Programs
- **Editors**: Nixvim with full IDE setup (LSPs, completion, telescope, git integration)
- **Shells**: Zsh with oh-my-zsh, autosuggestions, syntax highlighting
- **Terminal**: Alacritty
- **Launcher**: Rofi
- **Browsers**: Google Chrome
- **Dev tools**: rustup (stable), Go, Node.js, npm, Yarn, uv, ripgrep, direnv + nix-direnv
- **CLI tools**: Claude Code, fastfetch, zoxide
- **GUI apps**: Telegram Desktop, Google Chrome
- **Compatibility**: nix-ld for running unpatched binaries

### Services
- OpenSSH (key-only auth)
- sing-box proxy with VLESS Reality (TUN mode)
- NetworkManager

### XDG & Cache
- Full XDG Base Directory compliance
- Package manager caches centralized to `~/dev/cache/<name>` (npm, yarn, uv, pip, cargo, go, cuda)

## Secrets Management

Uses SOPS with age encryption. Keys are derived from SSH host keys (sakost-pc) or user age keys (portable).

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

## License

Personal configuration - use at your own risk.
