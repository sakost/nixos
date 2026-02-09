# NixOS Commit Workflow
1. Review all staged/unstaged changes
2. Run `nixos-rebuild build --flake .` to verify the build succeeds
3. If build fails, fix issues and rebuild until successful
4. Create a descriptive commit message summarizing the changes
5. Commit and push to origin
