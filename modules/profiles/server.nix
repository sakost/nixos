# Headless server profile: runs this host as an unattended SSH-only server.
# Only enabled by the `sakost-server` flake output — never in the host config.
{ config, lib, ... }:

let
  cfg = config.custom.profiles.server;
in {
  options.custom.profiles.server = {
    enable = lib.mkEnableOption "headless server mode";
  };

  config = lib.mkIf cfg.enable {
    # Headless Orca is reached through an SSH local-forward; no public
    # firewall opening is needed for its WebSocket listener.
    custom.services.orca.enable = true;

    # Force the desktop off regardless of what the host config enables.
    custom.desktop.hyprland.enable = lib.mkForce false;
    custom.desktop.greetd.enable = lib.mkForce false;
    custom.hardware.audio.enable = lib.mkForce false;
    custom.hardware.bluetooth.enable = lib.mkForce false;
    custom.hardware.mouse.enable = lib.mkForce false;
    custom.programs.steam.enable = lib.mkForce false;
    custom.programs.gnome-keyring.enable = lib.mkForce false;
    custom.programs.plymouth.enable = lib.mkForce false;
    custom.programs.powerline-fonts.enable = lib.mkForce false;

    # An unattended box must never sleep.
    systemd.targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };

    # The home-manager hyprland module auto-enables its xdg.portal module,
    # whose assertion requires the (disabled) system portal stack. No
    # graphical session exists in server mode, so switch it off entirely.
    home-manager.users.sakost.wayland.windowManager.hyprland.enable = lib.mkForce false;

    # The nvidia module enables services.xserver for the driver; with greetd
    # gone nixpkgs falls back to lightdm, which crash-loops headless. No X
    # stack is wanted at all — the nvidia driver install is keyed on
    # services.xserver.videoDrivers, which stays set, so CUDA still works.
    services.xserver.enable = lib.mkForce false;

    # Home-manager's dconfSettings activation needs the dconf D-Bus service,
    # which only the desktop stack provides; headless it fails the whole
    # home-manager-sakost unit ("name is not activatable").
    home-manager.users.sakost.dconf.enable = lib.mkForce false;

    # Brute-force protection for the internet-exposed SSH port.
    # LAN and Tailscale ranges are exempt so the backup path can never be banned.
    services.fail2ban = {
      enable = true;
      ignoreIP = [
        "192.168.1.0/24" # home LAN
        "100.64.0.0/10" # Tailscale CGNAT range
      ];
    };
    services.openssh.settings.MaxAuthTries = 3;

    # Tailscale: backup access path that needs no router port-forward
    # (routed direct past the sing-box TUN — see modules/services/proxy).
    # One-time `sudo tailscale up` login required before leaving (docs/server-mode.md).
    services.tailscale = {
      enable = true;
      openFirewall = true;
    };
    networking.firewall.trustedInterfaces = [ config.services.tailscale.interfaceName ];

    # WiFi power management is the top cause of headless WiFi boxes
    # silently dropping off the network.
    networking.networkmanager.wifi.powersave = false;

    # Hardware watchdog: a hard kernel hang triggers a reset instead of the
    # box staying dead until someone is physically present. TPM2 LUKS
    # auto-unlock brings it back up unattended. Runtime timeout is 2min
    # (not a more aggressive value) because a shorter one can spuriously
    # trip under severe memory-pressure thrash (e.g. a runaway remote nix
    # build stalling PID1); 2min still reboots a truly hung box fast enough
    # for an unattended absence.
    systemd.settings.Manager = {
      RuntimeWatchdogSec = "2min";
      RebootWatchdogSec = "2min";
    };
  };
}
