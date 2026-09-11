# Rust build-artifact placement.
#
# All cargo output must land on the @cache subvolume (nodatacow, NOT snapshotted)
# rather than in-tree on @dev (compressed, snapshotted hourly by btrbk).
#
# home/programs/zsh.nix has a chpwd hook that exports CARGO_TARGET_DIR, but a
# zsh hook only fires for *interactive* zsh. Builds started by agents, CI
# scripts, Makefiles or any `bash -c 'cargo build'` never saw it and wrote
# target/ in-tree — which is how ~370 GiB of build output ended up on @dev and
# got pinned into 16 hourly snapshots.
#
# This shim closes that gap: ~/.local/bin is first on PATH (see home/xdg.nix
# home.sessionPath), so it intercepts every cargo invocation in every shell.
{ config, pkgs, ... }:

let
  cacheBase = "${config.home.homeDirectory}/dev/cache";
in
{
  home.file.".local/bin/cargo" = {
    executable = true;
    text = ''
      #!${pkgs.runtimeShell}
      # Respect an explicit CARGO_TARGET_DIR (zsh hook, CI, --target-dir callers).
      if [ -z "''${CARGO_TARGET_DIR:-}" ]; then
        root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || true)
        if [ -n "$root" ]; then
          key=''${root#"$HOME"/}
          export CARGO_TARGET_DIR="${cacheBase}/cargo-target/''${key//\//_}"
        fi
      fi
      exec ${pkgs.rustup}/bin/cargo "$@"
    '';
  };
}
