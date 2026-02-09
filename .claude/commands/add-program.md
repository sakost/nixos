Add a new home-manager program configuration for "$ARGUMENTS".

Steps:
1. Create `home/programs/<name>.nix` with the program's home-manager config
2. Use the standard module header: `{ config, pkgs, ... }:`
3. Add the import to `home/sakost.nix`
4. Follow existing patterns from similar program configs in `home/programs/`