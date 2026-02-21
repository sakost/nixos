# CryptoPro CSP — GOST cryptographic provider (system-level)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.cryptopro;
  cryptopro = pkgs.callPackage ../../packages/cryptopro-csp.nix {
    inherit (cfg) version archiveHash cadesArchiveHash;
  };
  libdir = "${cryptopro}/opt/cprocsp/lib/amd64";

  # Setup script that uses cpconfig to register providers in CryptoPro's proprietary format.
  # Stored as a derivation so it's reproducible; executed via activation script.
  # Uses /opt/cprocsp symlink paths so cpconfig doesn't line-wrap them.
  shortLibdir = "/opt/cprocsp/lib/amd64";

  # Proxy wrapper for nmcades that manages trusted site approval via GUI dialog.
  #
  # CryptoPro's nmcades native messaging host asks the browser extension whether
  # the current page is a "trusted site". The extension checks an in-memory map
  # (empty on fresh start) and returns false. nmcades then checks its own config,
  # but the proprietary msz config format for trusted sites is unreliable on NixOS.
  # When both checks fail, nmcades hangs indefinitely.
  #
  # This wrapper sits between the browser and nmcades, intercepting approved_site
  # messages. It checks a persistent trusted sites file and shows a zenity dialog
  # for unknown sites, letting the user approve or deny on a per-site basis.
  nmcadesProxy = pkgs.writers.writePython3 "nmcades-proxy" {
    flakeIgnore = [ "E401" "E501" ];
  } ''
    import struct, json, subprocess, os, sys, select, fcntl
    from urllib.parse import urlparse

    NMCADES = "${cryptopro}/opt/cprocsp/bin/amd64/nmcades"
    LD_PATH = "${cryptopro}/opt/cprocsp/lib/amd64"
    ZENITY = "${pkgs.zenity}/bin/zenity"
    TRUSTED_FILE = os.path.expanduser(
        "~/.config/cryptopro-trusted-sites"
    )


    def load_trusted():
        try:
            with open(TRUSTED_FILE) as f:
                return set(
                    line.strip() for line in f if line.strip()
                )
        except FileNotFoundError:
            return set()


    def save_site(site):
        os.makedirs(os.path.dirname(TRUSTED_FILE), exist_ok=True)
        with open(TRUSTED_FILE, "a") as f:
            fcntl.flock(f, fcntl.LOCK_EX)
            f.write(site + "\n")


    def site_origin(url):
        p = urlparse(url)
        return f"{p.scheme}://{p.netloc}" if p.netloc else url


    def is_trusted(url, trusted):
        origin = site_origin(url)
        for pattern in trusted:
            if pattern == origin:
                return True
            if pattern.startswith("https://*."):
                domain = pattern[len("https://*."):]
                host = urlparse(url).hostname or ""
                if host == domain or host.endswith("." + domain):
                    return True
            if pattern.startswith("http://*."):
                domain = pattern[len("http://*."):]
                host = urlparse(url).hostname or ""
                if host == domain or host.endswith("." + domain):
                    return True
        return False


    def ask_user(url):
        origin = site_origin(url)
        try:
            rc = subprocess.call([
                ZENITY, "--question",
                "--title=CryptoPro CAdES",
                "--text="
                f"Сайт <b>{origin}</b> запрашивает доступ "
                "к криптографическому плагину CryptoPro.\n\n"
                "Разрешить?",
                "--ok-label=Разрешить",
                "--cancel-label=Запретить",
                "--width=400",
            ])
            return rc == 0
        except Exception:
            return False


    env = {**os.environ, "LD_LIBRARY_PATH": LD_PATH}
    try:
        proc = subprocess.Popen(
            [NMCADES] + sys.argv[1:],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            env=env,
        )
    except OSError:
        sys.exit(1)

    stdin_fd = sys.stdin.buffer
    stdout_fd = sys.stdout.buffer


    def read_msg(stream):
        raw = stream.read(4)
        if not raw or len(raw) < 4:
            return None
        length = struct.unpack("<I", raw)[0]
        data = stream.read(length)
        if len(data) < length:
            return None
        return json.loads(data)


    def write_msg(stream, msg):
        data = json.dumps(msg, separators=(",", ":")).encode("utf-8")
        stream.write(struct.pack("<I", len(data)))
        stream.write(data)
        stream.flush()


    trusted_sites = load_trusted()

    try:
        while proc.poll() is None:
            readable, _, _ = select.select(
                [stdin_fd, proc.stdout], [], [], 1.0
            )
            for fd in readable:
                if fd is stdin_fd:
                    msg = read_msg(stdin_fd)
                    if msg is None:
                        proc.terminate()
                        sys.exit(0)
                    write_msg(proc.stdin, msg)
                elif fd is proc.stdout:
                    msg = read_msg(proc.stdout)
                    if msg is None:
                        sys.exit(0)
                    dtype = msg.get("data", {}).get("type", "")
                    if dtype == "approved_site":
                        value = msg.get("data", {}).get("value", "")
                        if value.startswith("is_approved_site:"):
                            url = value[len("is_approved_site:"):].lstrip()
                            approved = is_trusted(url, trusted_sites)
                            if not approved:
                                approved = ask_user(url)
                                if approved:
                                    origin = site_origin(url)
                                    trusted_sites.add(origin)
                                    save_site(origin)
                            resp = {
                                **msg,
                                "data": {
                                    **msg["data"],
                                    "params": [{"type": "boolean", "value": approved}],
                                },
                            }
                            write_msg(proc.stdin, resp)
                            continue
                    write_msg(stdout_fd, msg)
    except (BrokenPipeError, OSError):
        pass
    finally:
        proc.terminate()
  '';

  # Native messaging host manifest for CAdES browser extension.
  # Points to the proxy wrapper that manages per-site trust approval via GUI dialog.
  # Both Chrome Web Store and Opera/Yandex Store extension IDs are included.
  nmcadesJson = builtins.toJSON {
    name = "ru.cryptopro.nmcades";
    description = "Chrome and Opera Native Messaging Host for CAdES Browser plug-in";
    path = "${nmcadesProxy}";
    type = "stdio";
    allowed_origins = [
      "chrome-extension://iifchhfnnmpdbibifmljnfjhpififfog/"
      "chrome-extension://epebfcehmdedogndhlcacafjaacknbcm/"
    ];
  };

  setupScript = let
    cpconfig = "${cryptopro}/bin/cpconfig";
  in pkgs.writeShellScript "cryptopro-setup" ''
    set -euo pipefail
    export LD_LIBRARY_PATH="${libdir}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    # Disable integrity check (autoPatchelfHook modifies ELF binaries)
    ${cpconfig} -ini '\config\parameters' -add string DisableIntegrity true
    # Set standard trial license from the official deb postinst script.
    # Only runs on first setup or derivation change (guarded by sentinel file).
    # A purchased license installed via `cpconfig -license -set` won't be overwritten
    # because this script is skipped when the sentinel matches the current store path.
    ${cpconfig} -license -set '5050N-40030-01BT7-2MA83-QF3T0' -use_expired 2>/dev/null || true
    ${cpconfig} -ini '\config\apppath' -add string libcsp.so ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\config\apppath' -add string libssp.so ${shortLibdir}/libssp.so
    ${cpconfig} -ini '\config\apppath' -add string libcapi20.so ${shortLibdir}/libcapi20.so
    ${cpconfig} -ini '\config\apppath' -add string librdrrndmbio_tui.so ${shortLibdir}/librdrrndmbio_tui.so
    ${cpconfig} -ini '\config\apppath' -add string libcapi10.so ${shortLibdir}/libcapi10.so
    ${cpconfig} -ini '\config\apppath' -add string libcpui.so ${shortLibdir}/libcpui.so
    ${cpconfig} -ini '\config\apppath' -add string librdrfat12.so ${shortLibdir}/librdrfat12.so
    ${cpconfig} -ini '\config\apppath' -add string librdrdsrf.so ${shortLibdir}/librdrdsrf.so
    ${cpconfig} -ini '\config\apppath' -add string librdrpcsc.so ${shortLibdir}/librdrpcsc.so
    ${cpconfig} -ini '\config\apppath' -add string librdrric.so ${shortLibdir}/librdrric.so
    ${cpconfig} -ini '\config\apppath' -add string librdrcryptoki.so ${shortLibdir}/librdrcryptoki.so
    ${cpconfig} -ini '\config\apppath' -add string librdrrutoken.so ${shortLibdir}/librdrrutoken.so
    # CAdES browser plugin libraries (needed by nmcades native messaging host)
    ${cpconfig} -ini '\config\apppath' -add string libnpcades.so ${shortLibdir}/libnpcades.so
    ${cpconfig} -ini '\config\apppath' -add string libcades.so ${shortLibdir}/libcades.so
    ${cpconfig} -ini '\config\apppath' -add string libcppcades.so ${shortLibdir}/libcppcades.so
    # CryptoPro loads libpcsclite via apppath, not dlopen/RUNPATH
    ${cpconfig} -ini '\config\apppath' -add string libpcsclite.so ${pkgs.pcsclite.lib}/lib/libpcsclite.so

    ${cpconfig} -hardware reader -add hdimage -name 'HDD key storage' > /dev/null 2>&1 || true
    # Register PCSC reader (uppercase — matches official postinst format)
    ${cpconfig} -ini '\config\KeyDevices\PCSC' -add string DLL librdrpcsc.so
    ${cpconfig} -ini '\config\KeyDevices\PCSC' -add long Group 1
    # PNP PCSC\Default section enables plug-and-play reader detection.
    # The Name param is created then deleted — the section must exist but Name
    # overwrites real reader names (per official postinst comment).
    ${cpconfig} -ini '\config\KeyDevices\PCSC\PNP PCSC\Default' -add string Name 'All PC/SC readers'
    ${cpconfig} -ini '\config\KeyDevices\PCSC\PNP PCSC\Default\Name' -delparam
    ${cpconfig} -ini '\config\parameters' -add long dynamic_readers 1
    ${cpconfig} -ini '\config\parameters' -add long dynamic_rdr_refresh_ms 1500

    # Rutoken media registrations (from cprocsp-rdr-rutoken postinst).
    # ATR patterns identify each Rutoken model so CryptoPro can use the correct driver.
    ${cpconfig} -ini '\config\KeyCarriers\RutokenLite' -add string DLL librdrrutoken.so
    ${cpconfig} -hardware media -add RutokenLite -name 'Rutoken lite' > /dev/null 2>&1 || true
    ${cpconfig} -hardware media -configure RutokenLite -add hex atr 3b8b015275746f6b656e6c697465c2
    ${cpconfig} -hardware media -configure RutokenLite -add hex mask ffffffffffffffffffffffffffffff
    ${cpconfig} -hardware media -configure RutokenLite -add string folders '0A00\\0B00\\0C00\\0D00\\0E00\\0F00\\1000\\1100\\1200\\1300\\1400\\1500\\1600\\1700\\1800'
    ${cpconfig} -hardware media -configure RutokenLite -add long size_1 60
    ${cpconfig} -hardware media -configure RutokenLite -add long size_2 70
    ${cpconfig} -hardware media -configure RutokenLite -add long size_3 8
    ${cpconfig} -hardware media -configure RutokenLite -add long size_4 60
    ${cpconfig} -hardware media -configure RutokenLite -add long size_5 70
    ${cpconfig} -hardware media -configure RutokenLite -add long size_6 300
    ${cpconfig} -hardware media -configure RutokenLite -add long size_7 8

    ${cpconfig} -ini '\config\KeyCarriers\RutokenECP' -add string DLL librdrrutoken.so
    ${cpconfig} -hardware media -add RutokenECP -name 'Rutoken ECP' > /dev/null 2>&1 || true
    ${cpconfig} -hardware media -configure RutokenECP -add hex atr 3b8b015275746f6b656e20445320c1
    ${cpconfig} -hardware media -configure RutokenECP -add hex mask ffffffffffffffffffffffffffffff
    ${cpconfig} -hardware media -configure RutokenECP -add string folders '0A00\\0B00\\0C00\\0D00\\0E00\\0F00\\1000\\1100\\1200\\1300\\1400\\1500\\1600\\1700\\1800'
    ${cpconfig} -hardware media -configure RutokenECP -add long size_1 60
    ${cpconfig} -hardware media -configure RutokenECP -add long size_2 70
    ${cpconfig} -hardware media -configure RutokenECP -add long size_3 8
    ${cpconfig} -hardware media -configure RutokenECP -add long size_4 60
    ${cpconfig} -hardware media -configure RutokenECP -add long size_5 70
    ${cpconfig} -hardware media -configure RutokenECP -add long size_6 300
    ${cpconfig} -hardware media -configure RutokenECP -add long size_7 8

    ${cpconfig} -ini '\config\KeyCarriers\RutokenECPSC' -add string DLL librdrrutoken.so
    ${cpconfig} -hardware media -add RutokenECPSC -name 'Rutoken ECP SC' > /dev/null 2>&1 || true
    ${cpconfig} -hardware media -configure RutokenECPSC -add hex atr 3b9c96005275746f6b656e4543507363
    ${cpconfig} -hardware media -configure RutokenECPSC -add hex mask ffffffffffffffffffffffffffffffff
    ${cpconfig} -hardware media -configure RutokenECPSC -add string folders '0A00\\0B00\\0C00\\0D00\\0E00\\0F00\\1000\\1100\\1200\\1300\\1400\\1500\\1600\\1700\\1800'
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_1 60
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_2 70
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_3 8
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_4 60
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_5 70
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_6 300
    ${cpconfig} -hardware media -configure RutokenECPSC -add long size_7 8

    ${cpconfig} -ini '\config\KeyCarriers\RutokenLiteSC2' -add string DLL librdrrutoken.so
    ${cpconfig} -hardware media -add RutokenLiteSC2 -name 'Rutoken Lite SC' > /dev/null 2>&1 || true
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add hex atr 3b9e96005275746f6b656e4c697465534332
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add hex mask ffffffffffffffffffffffffffffffffffff
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add string folders '0A00\\0B00\\0C00\\0D00\\0E00\\0F00\\1000\\1100\\1200\\1300\\1400\\1500\\1600\\1700\\1800'
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_1 60
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_2 70
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_3 8
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_4 60
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_5 70
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_6 300
    ${cpconfig} -hardware media -configure RutokenLiteSC2 -add long size_7 8

    ${cpconfig} -ini '\config\KeyCarriers\Rutoken' -add string DLL librdrrutoken.so
    ${cpconfig} -hardware media -add Rutoken -name 'Rutoken S' > /dev/null 2>&1 || true
    ${cpconfig} -hardware media -configure Rutoken -add hex atr 3b6f00ff00567275546f6b6e73302000009000
    ${cpconfig} -hardware media -configure Rutoken -add hex mask ffffffffffffffffffffffffffffffffffffff
    ${cpconfig} -hardware media -configure Rutoken -add string folders '0A00\\0B00\\0C00\\0D00\\0E00\\0F00\\1000'
    ${cpconfig} -hardware media -configure Rutoken -add long size_1 60
    ${cpconfig} -hardware media -configure Rutoken -add long size_2 70
    ${cpconfig} -hardware media -configure Rutoken -add long size_3 8
    ${cpconfig} -hardware media -configure Rutoken -add long size_4 60
    ${cpconfig} -hardware media -configure Rutoken -add long size_5 70
    ${cpconfig} -hardware media -configure Rutoken -add long size_6 300
    ${cpconfig} -hardware media -configure Rutoken -add long size_7 8

    ${cpconfig} -ini '\config\KeyCarriers\RutokenECPM' -add string DLL librdrrutoken.so
    ${cpconfig} -hardware media -add RutokenECPM -name 'Rutoken ECP 2151' > /dev/null 2>&1 || true
    ${cpconfig} -hardware media -configure RutokenECPM -add hex atr 3B18967275746F6B656E6D
    ${cpconfig} -hardware media -configure RutokenECPM -add hex mask ffffffffffffffffffffff
    ${cpconfig} -hardware media -configure RutokenECPM -add string folders '0A00\\0B00\\0C00\\0D00\\0E00\\0F00\\1000\\1100\\1200\\1300\\1400\\1500\\1600\\1700\\1800'
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_1 60
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_2 70
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_3 3072
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_4 60
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_5 70
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_6 300
    ${cpconfig} -hardware media -configure RutokenECPM -add long size_7 8
    ${cpconfig} -hardware rndm -add bio_tui -name 'Text bio random' -level 5 > /dev/null 2>&1 || true
    ${cpconfig} -ini '\config\Random\Bio_tui' -add string DLL librdrrndmbio_tui.so

    ${cpconfig} -defprov -setdef -provtype 75 -provname 'Crypto-Pro GOST R 34.10-2001 KC1 CSP'
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2001 KC1 CSP' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2001 KC1 CSP' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2001 KC1 CSP' -add long Type 75
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2001 Cryptographic Service Provider' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2001 Cryptographic Service Provider' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2001 Cryptographic Service Provider' -add long Type 75

    ${cpconfig} -defprov -setdef -provtype 80 -provname 'Crypto-Pro GOST R 34.10-2012 KC1 CSP'
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 KC1 CSP' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 KC1 CSP' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 KC1 CSP' -add long Type 80
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 Cryptographic Service Provider' -add long Type 80

    ${cpconfig} -defprov -setdef -provtype 81 -provname 'Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP'
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 KC1 Strong CSP' -add long Type 81
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 Strong Cryptographic Service Provider' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 Strong Cryptographic Service Provider' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro GOST R 34.10-2012 Strong Cryptographic Service Provider' -add long Type 81

    ${cpconfig} -defprov -setdef -provtype 1 -provname 'Crypto-Pro RSA Cryptographic Service Provider'
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro RSA Cryptographic Service Provider' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro RSA Cryptographic Service Provider' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro RSA Cryptographic Service Provider' -add long Type 1

    ${cpconfig} -defprov -setdef -provtype 16 -provname 'Crypto-Pro ECDSA and AES KC1 CSP'
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro ECDSA and AES KC1 CSP' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro ECDSA and AES KC1 CSP' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro ECDSA and AES KC1 CSP' -add long Type 16

    ${cpconfig} -defprov -setdef -provtype 24 -provname 'Crypto-Pro Enhanced RSA and AES KC1 CSP'
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro Enhanced RSA and AES KC1 CSP' -add string 'Image Path' ${shortLibdir}/libcsp.so
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro Enhanced RSA and AES KC1 CSP' -add string 'Function Table Name' CPCSP_GetFunctionTable
    ${cpconfig} -ini '\cryptography\Defaults\Provider\Crypto-Pro Enhanced RSA and AES KC1 CSP' -add long Type 24

    ${cpconfig} -ini '\cryptography\Defaults\Provider Types\Type 075' -add string 'TypeName' "GOST R 34.10-2001 Signature with Diffie-Hellman Key Exchange"
    ${cpconfig} -ini '\cryptography\Defaults\Provider Types\Type 080' -add string 'TypeName' "GOST R 34.10-2012 (256) Signature with Diffie-Hellman Key Exchange"
    ${cpconfig} -ini '\cryptography\Defaults\Provider Types\Type 081' -add string 'TypeName' "GOST R 34.10-2012 (512) Signature with Diffie-Hellman Key Exchange"
    ${cpconfig} -ini '\cryptography\Defaults\Provider Types\Type 001' -add string 'TypeName' "RSA Full (Signature and Key Exchange)"
    ${cpconfig} -ini '\cryptography\Defaults\Provider Types\Type 016' -add string 'TypeName' "ECDSA Full and AES"
    ${cpconfig} -ini '\cryptography\Defaults\Provider Types\Type 024' -add string 'TypeName' "RSA Full and AES"
  '';
in {
  options.custom.programs.cryptopro = {
    enable = lib.mkEnableOption "CryptoPro CSP GOST cryptographic provider";

    version = lib.mkOption {
      type = lib.types.str;
      default = "5.0";
      description = "CryptoPro CSP version.";
    };

    archiveHash = lib.mkOption {
      type = lib.types.nonEmptyStr;
      description = ''
        SHA-256 hash of the linux-amd64_deb.tgz archive.
        Download from https://cryptopro.ru/products/csp/downloads and compute with:
          nix hash file linux-amd64_deb.tgz
      '';
    };

    cadesArchiveHash = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      description = ''
        SHA-256 hash of a separate CAdES browser plugin archive (cades-linux-amd64.tar.gz).
        When set, CAdES packages are taken from this archive instead of the main CSP archive.
        Download from https://cryptopro.ru/products/cades/downloads and compute with:
          nix hash file cades-linux-amd64.tar.gz
      '';
    };

    enableSmartCards = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable smart card / token support (JaCarta, Rutoken) via pcscd.";
    };

    enableBrowserPlugin = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable CAdES browser plugin for Chrome/Chromium/Yandex Browser.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "sakost";
      description = "User account that will use CryptoPro (for per-user key storage).";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group for the CryptoPro user (used for shared tmp directory permissions).";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cryptopro ]
      ++ lib.optionals cfg.enableSmartCards (with pkgs; [
        pcsc-tools
        ccid
        opensc
      ]);

    # Smart card daemon for JaCarta / Rutoken tokens
    services.pcscd.enable = cfg.enableSmartCards;

    # Writable state directories, initial config, and /opt/cprocsp symlink.
    # The symlink ensures cpconfig writes short paths (/opt/cprocsp/lib/amd64/...)
    # instead of long nix store paths that get corrupted by line-wrapping.
    systemd.tmpfiles.rules = [
      "d /var/opt/cprocsp 0755 root root - -"
      "d /var/opt/cprocsp/keys 0700 root root - -"
      "d /var/opt/cprocsp/users 0755 root root - -"
      "d /var/opt/cprocsp/users/${cfg.user} 0700 ${cfg.user} ${cfg.group} - -"
      "d /var/opt/cprocsp/tmp 0770 root ${cfg.group} - -"
      "d /etc/opt/cprocsp 0755 root root - -"
      "C /etc/opt/cprocsp/config64.ini 0644 root root - ${cryptopro}/etc/opt/cprocsp/config64.ini"
      "L+ /opt/cprocsp - - - - ${cryptopro}/opt/cprocsp"
    ];

    # Register crypto providers via cpconfig (proprietary format, can't be hand-written).
    # NOTE: Activation scripts run before systemd-tmpfiles-setup.service, so we must
    # bootstrap directories, symlink, and config ourselves before running cpconfig.
    system.activationScripts.cryptopro-setup = {
      deps = [ "etc" ];
      text = ''
        mkdir -p /var/opt/cprocsp/keys /var/opt/cprocsp/users /var/opt/cprocsp/users/${cfg.user} /var/opt/cprocsp/tmp /etc/opt/cprocsp /opt
        chown ${cfg.user}:${cfg.group} /var/opt/cprocsp/users/${cfg.user}
        chmod 0700 /var/opt/cprocsp/users/${cfg.user}
        ln -sfn ${cryptopro}/opt/cprocsp /opt/cprocsp
        if [ ! -f /etc/opt/cprocsp/config64.ini ]; then
          cp ${cryptopro}/etc/opt/cprocsp/config64.ini /etc/opt/cprocsp/config64.ini
          chmod 0644 /etc/opt/cprocsp/config64.ini
        fi

        if [ ! -f /var/opt/cprocsp/.nixos-setup-done ] || \
           [ "$(cat /var/opt/cprocsp/.nixos-setup-done 2>/dev/null)" != "${cryptopro}" ]; then
          ${setupScript}
          echo "${cryptopro}" > /var/opt/cprocsp/.nixos-setup-done
        fi
      '';
    };

    # Native messaging host for CAdES browser extension
    environment.etc = lib.mkIf cfg.enableBrowserPlugin {
      "opt/chrome/native-messaging-hosts/ru.cryptopro.nmcades.json".text = nmcadesJson;
      "chromium/native-messaging-hosts/ru.cryptopro.nmcades.json".text = nmcadesJson;
      "opt/yandex/browser/native-messaging-hosts/ru.cryptopro.nmcades.json".text = nmcadesJson;
    };
  };
}
