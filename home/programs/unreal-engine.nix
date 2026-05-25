# Unreal Engine 5.4 — prebuilt Linux binary, run inside an FHS sandbox.
#
# nixpkgs has no Unreal Engine package (Epic's EULA forbids redistribution), so
# you download Epic's prebuilt Linux build yourself and run it through a
# buildFHSEnv wrapper that supplies a standard /usr, dynamic linker and all the
# runtime libraries the editor (and its bundled CEF browser) expect.
#
# Setup:
#   1. https://www.unrealengine.com/en-US/linux → sign in → download the 5.4.x
#      Linux build (a ~20 GB zip, e.g. Linux_Unreal_Engine_5.4.4.zip).
#   2. Extract it to ~/dev/UnrealEngine (on the @dev btrfs subvol; zstd-compressed,
#      plenty of free space) so that this exists:
#         ~/dev/UnrealEngine/Engine/Binaries/Linux/UnrealEditor
#      Override the location with $UE_ROOT if you keep it elsewhere.
#
# Entry points (on PATH via home.packages):
#   ue5-editor [project.uproject]  — launch UnrealEditor inside the FHS env
#   ue5-shell                      — interactive FHS shell with the C++ toolchain
#                                    (Setup.sh / GenerateProjectFiles.sh / make)
{ pkgs, ... }:

let
  defaultRoot = "$HOME/dev/UnrealEngine";

  # Everything the editor + CEF browser + C++ toolchain need at runtime.
  ueTargetPkgs = p: with p; [
    # Core C/C++ runtime
    stdenv.cc.cc
    zlib
    openssl
    icu
    libxml2
    expat

    # Audio
    alsa-lib
    libpulseaudio
    pipewire

    # Windowing / input
    SDL2
    wayland
    libxkbcommon
    libudev0-shim
    libx11
    libxext
    libxrender
    libxi
    libxrandr
    libxcursor
    libxscrnsaver
    libxcomposite
    libxfixes
    libxdamage
    libxtst
    libxcb

    # OpenGL / Vulkan (host NVIDIA driver comes in via /run/opengl-driver)
    libGL
    libglvnd
    mesa
    vulkan-loader
    vulkan-tools

    # Fonts / text
    fontconfig
    freetype

    # CEF (Chromium Embedded Framework — UE's in-app browser/marketplace UI)
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    libdrm
    gtk3
    glib
    pango
    cairo
    gdk-pixbuf
    libnotify

    # Toolchain for project generation / source builds / IDE (Rider, VSCode, clangd)
    dotnet-sdk_8
    clang_18
    lld_18
    clang-tools
    cmake
    gnumake
    ninja
    pkg-config
    python3
    git
  ];

  # Sourced inside the FHS env before runScript. Fixes the CoreCLR globalization
  # crash (HRESULT 0x80004005) and points the loader at NixOS's GPU driver.
  ueProfile = ''
    export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
    export LD_LIBRARY_PATH="/run/opengl-driver/lib:/run/opengl-driver-32/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    # Let the Vulkan loader find the NVIDIA ICD that NixOS installs here.
    export XDG_DATA_DIRS="/run/opengl-driver/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
  '';

  ue5-editor = pkgs.buildFHSEnv {
    name = "ue5-editor";
    targetPkgs = ueTargetPkgs;
    profile = ueProfile;
    runScript = pkgs.writeShellScript "ue5-editor-run" ''
      set -euo pipefail
      UE_ROOT="''${UE_ROOT:-${defaultRoot}}"
      editor="$UE_ROOT/Engine/Binaries/Linux/UnrealEditor"
      if [ ! -x "$editor" ]; then
        echo "UnrealEditor not found at: $editor" >&2
        echo "Extract Epic's prebuilt UE5.4 Linux build to ~/dev/UnrealEngine," >&2
        echo "or set UE_ROOT to your install. See home/programs/unreal-engine.nix." >&2
        exit 1
      fi
      exec "$editor" "$@"
    '';
  };

  ue5-shell = pkgs.buildFHSEnv {
    name = "ue5-shell";
    targetPkgs = ueTargetPkgs;
    profile = ''
      ${ueProfile}
      cd "''${UE_ROOT:-${defaultRoot}}" 2>/dev/null || true
      echo "Unreal Engine FHS shell — toolchain ready (dotnet, clang_18, cmake, make)."
      echo "Engine root: ''${UE_ROOT:-${defaultRoot}}"
    '';
    runScript = "bash";
  };
in
{
  home.packages = [
    ue5-editor
    ue5-shell
  ];

  # Show up in Walker / app launchers.
  xdg.desktopEntries.unreal-engine = {
    name = "Unreal Engine 5.4";
    genericName = "Game Engine";
    comment = "Unreal Engine editor (prebuilt, FHS-wrapped)";
    exec = "${ue5-editor}/bin/ue5-editor %F";
    icon = "applications-development";
    terminal = false;
    categories = [ "Development" "Game" ];
    mimeType = [ "application/x-ue-project" ];
  };
}
