# Prebuilt upstream release (static Go binary, no compile). agent-deck drives
# agent sessions through tmux, so tmux is put on its PATH.
{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  tmux,
}:

stdenvNoCC.mkDerivation rec {
  pname = "agent-deck";
  version = "1.16.30";

  src = fetchurl {
    url = "https://github.com/asheshgoplani/agent-deck/releases/download/v${version}/agent-deck_${version}_linux_amd64.tar.gz";
    hash = "sha256-iNlilIjxdzQFen2/n832QP+yMxG/ni6/TTBBI/+LJbw=";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 agent-deck $out/bin/agent-deck
    wrapProgram $out/bin/agent-deck --prefix PATH : ${lib.makeBinPath [ tmux ]}
    runHook postInstall
  '';

  meta = {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://github.com/asheshgoplani/agent-deck";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "agent-deck";
  };
}
