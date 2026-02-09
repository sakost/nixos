Add the package "$ARGUMENTS" to the NixOS configuration.

Determine the right location based on the package type:
- GUI apps (browsers, messengers, media players, etc.) → `home/programs/gui-apps.nix`
- CLI tools and dev utilities → `home/sakost.nix` in `home.packages`
- System-level packages (needed by services or hardware) → `hosts/sakost-pc/default.nix` or the relevant module
- Desktop/Wayland utilities → `modules/desktop/hyprland.nix`

Steps:
1. Verify the package name exists in nixpkgs (search with `nix search nixpkgs#<name>` if unsure)
2. Read the target file before editing
3. Add the package in alphabetical order within the existing list
4. Show the user what was added and where