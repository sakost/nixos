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

    # Auto-default Focusrite Scarlett Solo 3rd Gen as input source
    services.pipewire.wireplumber.extraConfig."51-scarlett-default-source" = {
      "monitor.alsa.rules" = [{
        matches = [{ "node.name" = "~alsa_input.*Scarlett_Solo.*Mic1.*"; }];
        actions.update-props = {
          "node.description" = "Focusrite Scarlett Solo";
          "priority.session" = 2500;
          "priority.driver" = 2500;
        };
      }];
    };

    # Audio control
    environment.systemPackages = [ pkgs.pavucontrol ];
  };
}
