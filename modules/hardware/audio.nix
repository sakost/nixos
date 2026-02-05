# Audio configuration module (PipeWire)
{ config, lib, pkgs, ... }:

let
  cfg = config.custom.hardware.audio;
in {
  options.custom.hardware.audio = {
    enable = lib.mkEnableOption "Audio support via PipeWire";
  };

  config = lib.mkIf cfg.enable {
    # PipeWire audio stack
    services.pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;

      # Low-latency configuration
      extraConfig.pipewire."92-low-latency" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.quantum" = 128;
          "default.clock.min-quantum" = 128;
        };
      };
    };

    # Audio control
    environment.systemPackages = [ pkgs.pavucontrol ];
  };
}
