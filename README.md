# NixOS Configuration

Multi-host NixOS flake configuration with Hyprland, Nvidia, and sing-box proxy.

## Hosts

- **sakost-pc-portable**: Current portable/temp disk setup
- **sakost-pc**: Future main PC with 2x NVMe (placeholder)

## Structure

```
├── flake.nix                 # Flake entry point
├── hosts/                    # Per-host configurations
│   ├── sakost-pc-portable/   # Portable host
│   └── sakost-pc/            # Main PC (template)
├── modules/                  # Shared NixOS modules
│   ├── hardware/             # GPU, CPU, audio, bluetooth
│   ├── desktop/              # Hyprland, greetd, XDG portals
│   ├── programs/             # zsh, fonts, git
│   └── services/             # SSH, networking, proxy
├── home/                     # Home-manager configuration
│   ├── sakost.nix            # User entry point
│   ├── programs/             # User programs (nixvim, zsh, etc.)
│   └── desktop/              # Hyprland user config
└── secrets/                  # SOPS-encrypted secrets
```

## Quick Start

### 1. Clone and Setup

```bash
# Clone to home directory
cd ~
git clone <repo-url> nixos-config
cd nixos-config
```

### 2. Setup SOPS Secrets

```bash
# Install age and sops
nix-shell -p age sops

# Generate age key (if not exists)
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Get your public key
age-keygen -y ~/.config/sops/age/keys.txt
# Add this public key to .sops.yaml

# Create sing-box config from template
cp secrets/sing-box-template.json secrets/sing-box.json
# Edit with your actual credentials
nvim secrets/sing-box.json

# Encrypt the config
sops -e -i secrets/sing-box.json
```

### 3. Build and Switch

```bash
# Build without switching (test)
sudo nixos-rebuild build --flake .#sakost-pc-portable

# Switch to new configuration
sudo nixos-rebuild switch --flake .#sakost-pc-portable
```

## Features

### Hardware
- Nvidia GPU with proprietary drivers
- Intel CPU microcode updates
- PipeWire audio (low-latency)
- Bluetooth support

### Desktop
- Hyprland Wayland compositor
- HDR support (4K@144Hz)
- greetd display manager with tuigreet
- XDG desktop portals

### Programs
- Nixvim with full IDE setup:
  - LSPs: Python, Rust, TypeScript, Nix, Lua, Go, Bash, JSON, YAML
  - Completion: nvim-cmp with snippets
  - UI: nvim-tree, lualine, bufferline, telescope
  - Git: gitsigns, lazygit
  - Extras: treesitter, autopairs, todo-comments, trouble
- Zsh with oh-my-zsh
- Alacritty terminal
- Rofi launcher

### Services
- OpenSSH (key-only auth)
- sing-box proxy with VLESS Reality (TUN mode)
- NetworkManager

## Secrets Management

This repo uses SOPS with age encryption for secrets.

**Files:**
- `.sops.yaml` - SOPS configuration with public keys
- `secrets/sing-box.json` - Encrypted sing-box config
- `secrets/sing-box-template.json` - Template (not encrypted)

**Never commit:**
- `secrets/keys/` - Private age keys
- Unencrypted secret files

### Decrypting Secrets (for editing)

```bash
# Edit encrypted file (auto-decrypt/encrypt)
sops secrets/sing-box.json

# Or decrypt to view
sops -d secrets/sing-box.json
```

## Adding a New Host

1. Create `hosts/<hostname>/` directory
2. Copy from existing host or create:
   - `default.nix` - Host configuration
   - `hardware.nix` - Run `nixos-generate-config` and copy
   - `disk-config.nix` - LUKS/filesystem setup
3. Add host to `flake.nix`:
   ```nix
   nixosConfigurations.<hostname> = mkHost "<hostname>";
   ```
4. Update `.sops.yaml` with new host's age public key

## Useful Commands

```bash
# Rebuild aliases (defined in home/programs/zsh.nix)
nrs   # nixos-rebuild switch --flake ~/nixos-config
nrb   # nixos-rebuild build --flake ~/nixos-config
nrt   # nixos-rebuild test --flake ~/nixos-config

# Edit config
ne    # nvim ~/nixos-config

# Check flake
nix flake check

# Update flake inputs
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
