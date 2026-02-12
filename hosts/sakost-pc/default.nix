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

  # Fix ownership of subvolume mount points during system activation
  system.activationScripts.fixSubvolumeOwnership = ''
    ${pkgs.coreutils}/bin/chown sakost:users \
      /home/sakost/games \
      /home/sakost/dev \
      /home/sakost/dev/models \
      /home/sakost/dev/data \
      /home/sakost/dev/cache
  '';

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
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 3d";
  };

  # Limit number of generations in boot menu
  boot.loader.systemd-boot.configurationLimit = 5;

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

  # Enable services
  custom.services = {
    ssh.enable = true;
    networking.enable = true;
    proxy.enable = true;
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
