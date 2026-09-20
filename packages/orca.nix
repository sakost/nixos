{
  lib,
  fetchurl,
  appimageTools,
  buildFHSEnv,
  writeShellScript,
  writeText,
}:

let
  pname = "orca";
  version = "1.4.200";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-yC2d31MkMeDaUexdGJmg4xWqu453/ORezOf61HM/yWo=";
  };

  # Exported inside every FHS sandbox built here, so the patched launcher can
  # tell whether it still has to enter one.
  fhsMarker = "ORCA_NIX_FHS_ENV";
  fhsProfile = "export ${fhsMarker}=1";

  # Generic "run this command inside the AppImage FHS sandbox" wrapper. It must
  # not depend on the extracted tree, otherwise the launcher patch below would
  # form a dependency cycle.
  fhsExec = buildFHSEnv (
    appimageTools.defaultFhsEnvArgs
    // {
      pname = "orca-fhs-exec";
      inherit version;
      runScript = writeShellScript "orca-fhs-exec" ''exec "$@"'';
      profile = fhsProfile;
    }
  );

  # Orca registers `~/.local/bin/orca` (dispatcher, rewritten on every
  # `orca serve` start) and `~/.local/bin/orca-ide` (symlink) pointing straight
  # at `<install>/resources/bin/orca-ide`. That script execs the Electron
  # binary next to it, which on NixOS only resolves its shared libraries inside
  # the FHS sandbox. Re-enter the sandbox when invoked from a plain shell.
  launcherGuard = writeText "orca-ide-fhs-guard" ''
    if [ -z "''${${fhsMarker}:-}" ]; then
      exec ${fhsExec}/bin/orca-fhs-exec "''${BASH_SOURCE[0]}" "$@"
    fi
  '';

  extracted = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      launcher=$out/resources/bin/orca-ide
      chmod u+w "$(dirname "$launcher")" "$launcher"
      # Fail loudly if upstream restructures the launcher instead of shipping
      # a silently unpatched one.
      grep -q '^set -euo pipefail$' "$launcher"
      sed -i '/^set -euo pipefail$/r ${launcherGuard}' "$launcher"
      grep -q '${fhsMarker}' "$launcher"
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  contents = extracted;
  profile = fhsProfile;

  # `orca` runs the app / `orca serve`; `orca-ide` is the CLI entrypoint the
  # orca-cli skill expects on Linux outside Orca-managed terminals.
  extraInstallCommands = ''
    ln -s ${extracted}/resources/bin/orca-ide $out/bin/orca-ide
  '';

  meta = {
    description = "AI orchestrator for coding agents";
    homepage = "https://onorca.dev";
    license = lib.licenses.mit;
    mainProgram = "orca";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
