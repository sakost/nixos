Rebuild the NixOS system to apply configuration changes.

Steps:
1. Run `nix flake check` to validate the flake
2. Run `sudo nixos-rebuild switch --flake .` to build and activate
3. If the build fails, analyze the error and suggest a fix
4. After successful rebuild, summarize what changed