# Temporary overlay: fix argocd fetchYarnDeps hash for x86_64-linux.
# The upstream hash (sha256-ekhSPW...) produces a stale offline cache.
# Remove this overlay once nixpkgs fixes the hash upstream.
final: prev: {
  argocd = prev.argocd.overrideAttrs (oldAttrs: {
    ui = oldAttrs.ui.overrideAttrs (uiAttrs: {
      offlineCache = prev.fetchYarnDeps {
        yarnLock = "${prev.argocd.src}/ui/yarn.lock";
        hash = "sha256-/B7FviD0a3VDmbbM59Ksmr8apuTRHrRbTtfX4QgO8JM=";
      };
    });
  });
}
