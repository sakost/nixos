Create a new NixOS system module for "$ARGUMENTS".

Follow the existing module pattern:
1. Determine the right category: `hardware`, `desktop`, `programs`, or `services`
2. Create the module file at `modules/<category>/<name>.nix` using the standard pattern:
   ```nix
   { config, lib, pkgs, ... }:
   let cfg = config.custom.<category>.<name>;
   in {
     options.custom.<category>.<name> = {
       enable = lib.mkEnableOption "<description>";
     };
     config = lib.mkIf cfg.enable { ... };
   };
   ```
3. Add the import to `modules/<category>/default.nix`
4. Enable it in the host config (`hosts/sakost-pc/default.nix`) with `custom.<category>.<name>.enable = true;`