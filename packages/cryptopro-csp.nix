# CryptoPro CSP — proprietary GOST cryptographic provider
# Download the archive from https://cryptopro.ru/products/csp/downloads (login required)
# Then: nix hash file linux-amd64_deb.tgz
#        nix-store --add-fixed sha256 linux-amd64_deb.tgz
{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  dpkg,
  glib,
  gtk3,
  pango,
  atk,
  pcsclite,
  zlib,
  glibc,
  gcc-unwrapped,
  libxxf86vm,
  version ? "5.0",
  archiveHash,
  cadesArchiveHash ? null,
}:

let
  # Optional separate CAdES browser plugin archive (newer versions ship independently)
  cadesArchive = if cadesArchiveHash != null then requireFile {
    name = "cades-linux-amd64.tar.gz";
    message = ''
      CAdES browser plugin update requires a manual download.

      1. Go to https://cryptopro.ru/products/cades/downloads
      2. Download "КриптоПро ЭЦП Browser plug-in для Linux (x64)" — cades-linux-amd64.tar.gz
      3. Run: nix hash file cades-linux-amd64.tar.gz
      4. Set the hash in custom.programs.cryptopro.cadesArchiveHash
      5. Run: nix-store --add-fixed sha256 cades-linux-amd64.tar.gz
      6. Rebuild: sudo nixos-rebuild switch --flake .#sakost-pc
    '';
    hash = cadesArchiveHash;
  } else null;
in

stdenv.mkDerivation {
  pname = "cryptopro-csp";
  inherit version;

  src = requireFile {
    name = "linux-amd64_deb.tgz";
    message = ''
      CryptoPro CSP requires a manual download.

      1. Go to https://cryptopro.ru/products/csp/downloads
      2. Log in (registration is free)
      3. Download "КриптоПро CSP для Linux (x64, deb)" — the file linux-amd64_deb.tgz
      4. Run: nix hash file linux-amd64_deb.tgz
      5. Set the hash in custom.programs.cryptopro.archiveHash
      6. Run: nix-store --add-fixed sha256 linux-amd64_deb.tgz
      7. Rebuild: sudo nixos-rebuild switch --flake .#sakost-pc
    '';
    hash = archiveHash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    glib
    gtk3
    pango
    atk
    pcsclite
    zlib
    glibc
    gcc-unwrapped.lib
    libxxf86vm
  ];

  dontConfigure = true;
  dontBuild = true;

  # Some internal libs are loaded via dlopen and won't be found at build time
  autoPatchelfIgnoreMissingDeps = [
    "libcapi10.*"
    "libcapi20.*"
    "librdrsup.*"
    "libssp.*"
  ];

  unpackPhase = ''
    mkdir -p source
    tar -xzf $src -C source
    ${lib.optionalString (cadesArchive != null) ''
      tar -xzf ${cadesArchive} -C source
    ''}
  '';

  installPhase = ''
    mkdir -p $out

    # List of deb packages to extract
    local debs=(
      lsb-cprocsp-base
      lsb-cprocsp-rdr-64
      lsb-cprocsp-kc1-64
      lsb-cprocsp-capilite-64
      lsb-cprocsp-ca-certs
      lsb-cprocsp-pkcs11-64
      cprocsp-rdr-gui-gtk-64
      cprocsp-rdr-pcsc-64
      cprocsp-rdr-jacarta-64
      cprocsp-rdr-rutoken-64
      cprocsp-cptools-gtk-64
      cprocsp-pki-cades-64
      cprocsp-pki-plugin-64
    )

    for pattern in "''${debs[@]}"; do
      for deb in source/linux-amd64_deb/$pattern*.deb source/cades-linux-amd64/$pattern*.deb; do
        if [ -f "$deb" ]; then
          echo "Extracting: $deb"
          dpkg-deb -x "$deb" $out
        fi
      done
    done

    # Create bin symlinks
    mkdir -p $out/bin
    for bin in $out/opt/cprocsp/bin/amd64/*; do
      [ -f "$bin" ] && ln -sf "$bin" "$out/bin/$(basename "$bin")"
    done
    for bin in $out/opt/cprocsp/sbin/amd64/*; do
      [ -f "$bin" ] && ln -sf "$bin" "$out/bin/$(basename "$bin")"
    done

    # Create lib symlinks (skip libssp.so — conflicts with GCC's stack protector lib)
    mkdir -p $out/lib
    for solib in $out/opt/cprocsp/lib/amd64/*; do
      [ -f "$solib" ] || continue
      case "$(basename "$solib")" in
        libssp.so*) continue ;;
      esac
      ln -sf "$solib" "$out/lib/$(basename "$solib")"
    done

    # librdrpcsc.so dlopen()s libpcsclite.so at runtime.
    # Place it in $out/lib (already in RUNPATH) so dlopen finds it.
    ln -sf ${pcsclite.lib}/lib/libpcsclite.so.1 $out/lib/libpcsclite.so.1
    ln -sf ${pcsclite.lib}/lib/libpcsclite.so $out/lib/libpcsclite.so
  '';

  # Help autoPatchelfHook find CryptoPro's own internal libraries
  preFixup = ''
    addAutoPatchelfSearchPath $out/opt/cprocsp/lib/amd64
  '';

  meta = with lib; {
    description = "CryptoPro CSP — GOST cryptographic provider for digital signatures";
    homepage = "https://cryptopro.ru/products/csp";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
