# Steam gaming platform (system-level)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.programs.steam;
in {
  options.custom.programs.steam = {
    enable = lib.mkEnableOption "Steam gaming platform";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      gamescopeSession.enable = true;
    };

    # Gamescope — SteamOS compositing window manager for games
    # Wraps the binary with capabilities and default args for 4K/144Hz NVIDIA HDR
    programs.gamescope = {
      enable = true;
      args = [
        "-W" "3840"         # Output width (monitor native)
        "-H" "2160"         # Output height (monitor native)
        "--adaptive-sync"   # VRR/G-Sync to prevent tearing
        "--hdr-enabled"     # HDR output passthrough
        "--force-grab-cursor"
      ];
      env = {
        DXVK_STATE_CACHE_PATH = "~/dev/cache/dxvk";
        # Required for HDR in DXVK (DX9/11 games)
        DXVK_HDR = "1";
        # Required for HDR in VKD3D-proton (DX12 games)
        ENABLE_GAMESCOPE_WSI_LAYER = "1";
      };
    };

    # Steam controller support (Steam controller, Steam Deck controller)
    hardware.steam-hardware.enable = true;

    # PS5 DualSense controller — load hid-playstation kernel module
    boot.kernelModules = [ "hid_playstation" ];

    # Gamemode — on-demand performance optimisation daemon
    programs.gamemode.enable = true;
  };
}
