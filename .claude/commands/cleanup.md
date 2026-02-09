Run Nix garbage collection to free disk space.

Steps:
1. Show current store size with `du -sh /nix/store`
2. Run `nix store gc` to collect garbage
3. Run `nix store optimise` to deduplicate the store
4. Show the new store size and how much space was freed