# cargo-cross — zero-setup cross compilation for Rust via Podman
# Built from git main branch (upstream hasn't released past v0.2.5 since 2023)
{ pkgs, ... }:

let
  cargo-cross-git = pkgs.rustPlatform.buildRustPackage {
    pname = "cargo-cross";
    version = "0.2.5-unstable-2026-03-25";

    src = pkgs.fetchFromGitHub {
      owner = "cross-rs";
      repo = "cross";
      rev = "f86fd03bb70b4c6802847c18087e21391498b0b4";
      hash = "sha256-dfAbLPreribR5SH8G9exgWn5nveTWg965cpTC/PAFUs=";
    };

    cargoHash = "sha256-6r0EToPGtLic2yBzfzvT5If6kL5DFS9rm3A3TvW/xYY=";

    doCheck = false;

    meta = with pkgs.lib; {
      description = "Zero setup cross compilation and cross testing";
      homepage = "https://github.com/cross-rs/cross";
      license = with licenses; [ asl20 mit ];
      mainProgram = "cross";
    };
  };
in
{
  home.packages = [ cargo-cross-git ];

  home.sessionVariables = {
    CROSS_CONTAINER_ENGINE = "podman";
  };
}
