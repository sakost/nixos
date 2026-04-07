# GUI applications
{ config, pkgs, inputs, lib, ... }:

let
  yandex-browser = inputs.yandex-browser.packages.x86_64-linux.default;

  # Wrap Yandex Browser with CryptoPro GOST TLS library path so it can
  # find libssp.so.4 (CryptoPro's Secure Sockets Provider for GOST TLS).
  yandex-browser-with-cryptopro = pkgs.symlinkJoin {
    name = "yandex-browser-with-cryptopro";
    paths = [ yandex-browser ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in $out/bin/yandex-browser $out/bin/yandex-browser-stable; do
        if [ -f "$bin" ]; then
          wrapProgram "$bin" \
            --suffix LD_LIBRARY_PATH : "/opt/cprocsp/lib/amd64"
        fi
      done
    '';
  };

  # Upstream claude-desktop-linux-flake still references `nodePackages.asar`,
  # which was removed from nixpkgs on 2026-03-03. Override the auto-supplied
  # `nodePackages` arg to point its `.asar` lookup at the new top-level `asar`
  # package. Drop this override once the upstream flake is updated.
  claude-desktop = inputs.claude-desktop.packages.x86_64-linux.claude-desktop.override {
    nodePackages = { inherit (pkgs) asar; };
  };
in
{
  home.packages = with pkgs; [
    telegram-desktop
    google-chrome
    claude-desktop
    yandex-browser-with-cryptopro
    spotify
    zoom-us
    loupe
    obsidian
  ];
}
