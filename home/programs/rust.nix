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
# (A `--target-dir` flag still overrides the env var and bypasses the shim.)
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
      # An explicit CARGO_TARGET_DIR is respected unless it points under $HOME
      # but outside the cache: agents export per-run dirs like ~/dev/vt/rr926,
      # which land on snapshotted @dev (50+ GiB each). Those are remapped into
      # the cache; /tmp and other off-home paths are left alone.
      dir=''${CARGO_TARGET_DIR:-}
      case "$dir" in
        "${cacheBase}"/*) ;;
        "$HOME"/*)
          key=''${dir#"$HOME"/}
          export CARGO_TARGET_DIR="${cacheBase}/cargo-target/''${key//\//_}"
          ;;
        "")
          root=$(${pkgs.git}/bin/git rev-parse --show-toplevel 2>/dev/null || true)
          if [ -n "$root" ]; then
            key=''${root#"$HOME"/}
            export CARGO_TARGET_DIR="${cacheBase}/cargo-target/''${key//\//_}"
          fi
          ;;
      esac
      exec ${pkgs.rustup}/bin/cargo "$@"
    '';
  };
}
