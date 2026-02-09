Show what changed between the current and previous NixOS generation.

Run `nvd diff $(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -2 | head -1) /run/current-system` to compare the last two system generations.

If `nvd` is not available, use `nix store diff-closures` instead:
`nix store diff-closures $(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -2 | head -1) /run/current-system`

Summarize the added, removed, and updated packages.