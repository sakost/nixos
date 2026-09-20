# RTK — AI token optimizer that compresses shell output for coding agents
{ pkgs, ... }:

{
  home.packages = [
    (pkgs.rtk.overrideAttrs (_old: {
      # rtk 0.43.0 builds, but its test target fails under current nixpkgs
      # because upstream sets -D warnings and has dead-code warnings.
      doCheck = false;
    }))
  ];
}
