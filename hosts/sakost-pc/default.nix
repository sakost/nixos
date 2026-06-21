# Host configuration for sakost-pc (main PC with 2x NVMe)
# Configure this when setting up the main PC
{
  config,
  lib,
  pkgs,
  inputs,
  hostname,
  ...
}:

{
  imports = [
    ./hardware.nix
    ./disk-config.nix
    ../../modules/hardware
    ../../modules/desktop
    ../../modules/programs
    ../../modules/services
  ];

  # Host identity
  networking.hostName = hostname;

  # SOPS - use SSH host key for age decryption (available before /home mounts)
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  # OpenClaw secrets (API keys and tokens loaded via EnvironmentFile)
  sops.secrets."openclaw-env" = {
    sopsFile = ../../secrets/openclaw-env;
    format = "binary";
    mode = "0400";
    owner = "sakost";
  };

  # Fix ownership of subvolume mount points (runs after mounts are available)
  systemd.tmpfiles.rules = [
    "z /home/sakost/games - sakost users - -"
    "z /home/sakost/dev - sakost users - -"
    "z /home/sakost/dev/models - sakost users - -"
    "z /home/sakost/dev/data - sakost users - -"
    "z /home/sakost/dev/cache - sakost users - -"
    "z /home/sakost/.snapshots - sakost users - -"
    # Nix build dir: root-owned and not world-writable, swept after 30d.
    "d /var/tmp/nix-build 0755 root root 30d"
  ];

  # Timezone and locale
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "ru_RU.UTF-8";
  };
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "ru_RU.UTF-8/UTF-8"
  ];

  # Nix settings
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Build large derivations on disk, not in the tmpfs /tmp (see boot.tmp below).
    # Must be a dedicated, non-world-writable dir: Nix rejects a world-writable
    # build-dir (e.g. /var/tmp itself, mode 1777) for security. The dir lives on
    # the 708G root and its contents are swept by systemd-tmpfiles at 30d below.
    build-dir = "/var/tmp/nix-build";
  };
  # Legacy fallback for Nix versions that ignore build-dir. TMPDIR is not subject
  # to the world-writable check (per-build subdirs are created mode 0700).
  # The dir itself is created via systemd.tmpfiles.rules above.
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp/nix-build";
  nixpkgs.config.allowUnfree = true;
  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  # Limit number of generations in boot menu
  boot.loader.systemd-boot.configurationLimit = 5;

  # Mount /tmp as tmpfs so it lives in RAM and is wiped on every reboot.
  # Default size is 50% of RAM (~31G); with 64G that is plenty for app scratch,
  # and large Nix builds are redirected to /var/tmp on disk (see nix.settings).
  boot.tmp.useTmpfs = true;

  # Enable hardware features
  custom.hardware = {
    nvidia.enable = true;
    intel-cpu.enable = true;
    audio.enable = true;
    bluetooth.enable = true;
    mouse.enable = true;
    tpm.enable = true;
  };

  # Enable desktop features
  custom.desktop = {
    hyprland.enable = true;
    greetd.enable = true;
  };

  # Enable programs
  custom.programs.steam.enable = true;
  custom.programs.virt-manager.enable = true;
  custom.programs.veracrypt.enable = true;
  custom.programs.gnome-keyring.enable = true;
  custom.programs.plymouth.enable = true;
  custom.programs.powerline-fonts.enable = true;
  custom.programs.cryptopro = {
    enable = true;
    archiveHash = "sha256-oM/0hvv2D3a2HTUnSUWzAuUyfQ8SY+RlrU09Kj1f+rQ=";
    cadesArchiveHash = "sha256-0+XYOVwhgZmTw4Q4fiamVZp6CTyUwikmIDoBdp9Px54=";
  };

  # Enable services
  custom.services = {
    ssh.enable = true;
    networking.enable = true;
    proxy.enable = true;
    snapshots.enable = true;
  };

  # User configuration
  users.users.sakost = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "kvm"
    ];
    shell = pkgs.zsh;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    wget
    tree
    sops
    age
    parted
    sbctl
  ];

  # State version - set this when first installing
  system.stateVersion = "25.11";
}
