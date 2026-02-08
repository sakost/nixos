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

  # SOPS age key configuration
  sops.age.keyFile = "/home/sakost/.config/sops/age/keys.txt";

  # Timezone and locale
  time.timeZone = "Europe/Moscow";

  # Nix settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  # Enable hardware features
  custom.hardware = {
    nvidia.enable = true;
    intel-cpu.enable = true;
    audio.enable = true;
    bluetooth.enable = true;
  };

  # Enable desktop features
  custom.desktop = {
    hyprland.enable = true;
    greetd.enable = true;
  };

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
    ];
    shell = pkgs.zsh;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    git
    wget
    tree
  ];

  # State version - set this when first installing
  system.stateVersion = "25.11";
}
