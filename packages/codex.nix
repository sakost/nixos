{
  lib,
  fetchFromGitHub,
  rustPlatform,
  upstreamCodex,
}:

let
  minimumVersion = "0.154.0";
  patchedRustPlatform = rustPlatform // {
    buildRustPackage = attrs:
      rustPlatform.buildRustPackage (
        finalAttrs:
        (attrs finalAttrs)
        // {
          version = minimumVersion;

          src = fetchFromGitHub {
            owner = "openai";
            repo = "codex";
            tag = "rust-v${finalAttrs.version}";
            hash = "sha256-Nm+61N6YHxGhjLsm/giVSEg4QvJmIgWxyTQ1L89kpCs=";
          };

          cargoHash = "sha256-9F8dyEiVkhelrIyfQ9ZkvuxfIYNN6akbpadREa4A1n0=";
        }
      );
  };
in
if lib.versionAtLeast upstreamCodex.version minimumVersion then
  upstreamCodex
else
  upstreamCodex.override { rustPlatform = patchedRustPlatform; }
