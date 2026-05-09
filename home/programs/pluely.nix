# Pluely — open-source AI desktop assistant (Tauri-based Cluely alternative).
# Upstream ships only AppImage/.deb/.rpm/.dmg; we wrap the linux AppImage.
{ config, pkgs, ... }:

let
  pname = "pluely";
  version = "0.1.9";

  src = pkgs.fetchurl {
    url = "https://github.com/iamsrikanthnani/pluely/releases/download/app-v${version}/Pluely_${version}_amd64.AppImage";
    hash = "sha256-lULs74QaaPdlOosMmJRmWgI9bryuIc/ZbHLPNEf8ATw=";
  };

  appimageContents = pkgs.appimageTools.extractType2 { inherit pname version src; };

  pluely = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      # Use the canonical desktop entry from usr/lib/Pluely (full freedesktop
      # metadata: Categories, MimeType, Keywords). The copies at the AppDir
      # root and usr/share/applications are minimal stubs with empty
      # Categories= which most launchers (Walker, GNOME Shell) filter out.
      install -Dm444 ${appimageContents}/usr/lib/Pluely/pluely.desktop \
        $out/share/applications/pluely.desktop

      for size in 32x32 128x128 256x256@2; do
        icon="${appimageContents}/usr/share/icons/hicolor/$size/apps/pluely.png"
        if [ -f "$icon" ]; then
          install -Dm444 "$icon" "$out/share/icons/hicolor/$size/apps/pluely.png"
        fi
      done
    '';
  };
in
{
  home.packages = [ pluely ];
}
