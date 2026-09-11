{
  lib,
  fetchurl,
  appimageTools,
}:

appimageTools.wrapType2 {
  pname = "orca";
  version = "1.4.200";

  src = fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v1.4.200/orca-linux.AppImage";
    hash = "sha256-yC2d31MkMeDaUexdGJmg4xWqu453/ORezOf61HM/yWo=";
  };

  meta = {
    description = "AI orchestrator for coding agents";
    homepage = "https://onorca.dev";
    license = lib.licenses.mit;
    mainProgram = "orca";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
