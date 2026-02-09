# NixOS Config - Claude Code Guidelines

## Repository overview

Multi-host NixOS flake for user **sakost**. Uses nixpkgs unstable, home-manager, nixvim, sops-nix, lanzaboote (secure boot), and android-nixpkgs.

Two hosts defined via `mkHost` in `flake.nix`:
- `sakost-pc` — main desktop (Intel CPU, NVIDIA GPU)
- `sakost-pc-portable` — portable/temp disk setup

## Directory structure

```
hosts/<hostname>/       — Per-host config (hardware.nix, disk-config.nix, default.nix)
modules/                — System-level NixOS modules with custom.* options
  hardware/             — nvidia, intel-cpu, amd-cpu, audio, bluetooth, mouse, tpm
  desktop/              — hyprland, greetd, xdg-portals
  programs/             — fonts, git, zsh, nix-ld, android
  services/             — ssh, networking, proxy, podman
home/                   — Home-manager config (imported from home/sakost.nix)
  programs/             — Per-program configs (waybar, alacritty, zsh, rofi, nixvim, etc.)
  desktop/              — User-level hyprland config
secrets/                — SOPS-encrypted secrets (age-based)
```

## Key patterns

### System modules use `custom.*` options
All system modules under `modules/` follow this pattern:
```nix
options.custom.<category>.<name>.enable = lib.mkEnableOption "...";
config = lib.mkIf cfg.enable { ... };
```
Hosts enable features via `custom.hardware.nvidia.enable = true;`, etc.

### Home-manager is integrated into the NixOS config
Home-manager runs as a NixOS module (not standalone). All user config is under `home/` and imported via `home/sakost.nix`. Use `home.packages` for user-level packages.

### Where to add packages
- **GUI apps** (browsers, messengers, etc.) → `home/programs/gui-apps.nix`
- **CLI tools** (dev tools, utilities) → `home/sakost.nix` in `home.packages`
- **System packages** (low-level, needed by services) → `hosts/<hostname>/default.nix` or the relevant module
- **Desktop/Wayland utilities** → `modules/desktop/hyprland.nix`

### Per-program home-manager configs
Each program with non-trivial config gets its own file in `home/programs/` (e.g., `waybar.nix`, `alacritty.nix`). Import it in `home/sakost.nix`.

## Desktop environment

- **Compositor**: Hyprland (Wayland) with XWayland
- **Status bar**: Waybar (managed via home-manager systemd service)
- **Launcher**: Rofi
- **Terminal**: Alacritty
- **Editor**: Neovim via nixvim
- **Login manager**: greetd
- **Theme**: TokyoNight-inspired dark theme

## Secrets management

Uses sops-nix with age encryption. Keys derived from SSH host keys. Config in `.sops.yaml`.

## Commit style

Conventional commits: `feat(<scope>): description`, `fix(<scope>): ...`, `docs: ...`
Scopes match the area of change: `home`, `waybar`, `locale`, `flutter`, `hardware`, `nixvim`, etc.

## Slash commands

- `/add-package <name>` — add a package to the right place (gui-apps, home.packages, system, etc.)
- `/add-module <name>` — create a new system module under `modules/` with the `custom.*` option pattern
- `/add-program <name>` — create a new home-manager program config under `home/programs/`
- `/search-option <query>` — search NixOS/home-manager options and check if already used

## Important notes

- Timezone is `Europe/Moscow`, locale is `en_US.UTF-8` with Russian (`ru_RU.UTF-8`) for `LC_TIME`
- `nixpkgs.config.allowUnfree = true` — unfree packages are allowed
- Flake inputs are passed via `specialArgs` (system) and `extraSpecialArgs` (home-manager) — use `inputs` to reference them in modules
- Never commit files matching patterns in `.gitignore` (secrets/keys/, *.age, result, etc.)