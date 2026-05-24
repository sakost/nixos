# OpenClaude — open-source coding-agent CLI that drives OpenAI-compatible,
# Gemini, Ollama, DeepSeek, and other backends with the same Claude-Code-style
# workflow. Configure providers interactively with `/provider` inside the CLI.
#
# Not in nixpkgs. The published npm tarball ships a prebuilt dist/cli.mjs but
# leaves runtime deps (67 of them) as externals, so we use buildNpmPackage with
# a minimal wrapper package.json + lockfile under ./openclaude/ to fetch
# transitive deps reproducibly. Bump:
#   1. Update version below.
#   2. cd home/programs/openclaude && npm install --package-lock-only --omit=dev --ignore-scripts
#   3. nix run nixpkgs#prefetch-npm-deps -- home/programs/openclaude/package-lock.json
#      → put the printed hash into `npmDepsHash`.
{ pkgs, lib, ... }:

let
  openclaude = pkgs.buildNpmPackage rec {
    pname = "openclaude";
    version = "0.14.0";

    src = ./openclaude;

    npmDepsHash = "sha256-rEkxgH8/ivNMbJfPgzOMjQYjUniQYScAmhnhrP8KQqo=";

    # The wrapper package has no build step — we only need npm ci to populate
    # node_modules, then we wrap the bin entry from @gitlawb/openclaude.
    dontNpmBuild = true;

    nodejs = pkgs.nodejs_22;

    installPhase = ''
      runHook preInstall

      install -d "$out/lib"
      cp -r node_modules "$out/lib/node_modules"

      install -d "$out/bin"
      makeWrapper ${lib.getExe pkgs.nodejs_22} "$out/bin/openclaude" \
        --add-flags "$out/lib/node_modules/@gitlawb/openclaude/bin/openclaude" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep ]}

      runHook postInstall
    '';

    meta = {
      description = "Open-source coding-agent CLI for OpenAI-compatible, Gemini, Ollama, and other LLM providers";
      homepage = "https://github.com/Gitlawb/openclaude";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      mainProgram = "openclaude";
    };
  };
in
{
  home.packages = [ openclaude ];
}
