# Host configuration for sakost-pc-portable (temp disk setup)
{ config, lib, pkgs, inputs, hostname, ... }:

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

  # Ensure sops age key directory and file have correct ownership
  systemd.tmpfiles.rules = [
    "d /home/sakost/.config/sops/age 0700 sakost users - -"
    "f /home/sakost/.config/sops/age/keys.txt 0600 sakost users - -"
  ];

  # Timezone and locale
  time.timeZone = "Europe/Moscow";

  # Nix settings
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
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
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    shell = pkgs.zsh;
  };

  # System packages (minimal, most go in modules)
  environment.systemPackages = with pkgs; [
    git
    wget
    tree
    sops
    age
    parted
  ];

  # State version - DO NOT CHANGE after initial install
  system.stateVersion = "25.11";
}
