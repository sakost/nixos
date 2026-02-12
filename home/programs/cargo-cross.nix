# cargo-cross — zero-setup cross compilation for Rust via Podman
{ pkgs, ... }:

{
  home.packages = [ pkgs.cargo-cross ];

  home.sessionVariables = {
    CROSS_CONTAINER_ENGINE = "podman";
  };
}
