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

      # RNNoise denoised virtual microphone
      extraConfig.pipewire."93-rnnoise-denoised-mic" = {
        "context.modules" = [{
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Scarlett Solo (Denoised)";
            "media.name" = "Scarlett Solo (Denoised)";
            "filter.graph" = {
              nodes = [{
                type = "ladspa";
                name = "rnnoise";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_mono";
                control = {
                  # 0 = always pass, 99 = very aggressive gating (default ~50)
                  "VAD Threshold (%)" = 50.0;
                  # Keep audio flowing after speech stops (default 500)
                  "VAD Grace Period (ms)" = 500;
                  # Retroactive capture for word-initial transients (default 100)
                  "Retroactive VAD Grace (ms)" = 100;
                };
              }];
            };
            "capture.props" = {
              "node.name" = "rnnoise_source";
              "node.passive" = true;
              "audio.rate" = 48000;
            };
            "playback.props" = {
              "node.name" = "rnnoise_sink";
              "media.class" = "Audio/Source";
              "audio.rate" = 48000;
              "priority.session" = 3000;
              "priority.driver" = 3000;
            };
          };
        }];
      };
    };

    # Scarlett raw capture — labeled "Raw", lower priority so denoised is default
    services.pipewire.wireplumber.extraConfig."51-scarlett-default-source" = {
      "monitor.alsa.rules" = [{
        matches = [{ "node.name" = "~alsa_input.*Scarlett_Solo.*Mic1.*"; }];
        actions.update-props = {
          "node.description" = "Scarlett Solo (Raw)";
          "priority.session" = 2000;
          "priority.driver" = 2000;
        };
      }];
    };

    # Audio control
    environment.systemPackages = [
      pkgs.pavucontrol
      pkgs.rnnoise-plugin
    ];
  };
}
