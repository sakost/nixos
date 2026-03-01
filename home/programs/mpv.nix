# mpv video player — GPU-accelerated, TokyoNight themed
{ theme, pkgs, ... }:

let
  c = theme.colors;
in
{
  programs.mpv = {
    enable = true;

    config = {
      # Hardware decoding (NVIDIA NVDEC)
      hwdec = "auto-safe";
      vo = "gpu-next";
      gpu-api = "vulkan";

      # OSD styling — TokyoNight palette
      osd-font = theme.fonts.mono;
      osd-font-size = theme.fonts.size.medium;
      osd-color = c.fg;
      osd-border-color = c.bg-dark;
      osd-border-size = 2;
      osd-bar-align-y = 0.9;

      # Subtitles
      sub-font = theme.fonts.mono;
      sub-font-size = 36;
      sub-color = c.fg;
      sub-border-color = c.bg-dark;
      sub-border-size = 2;
      sub-shadow-offset = 1;
      sub-shadow-color = c.bg;

      # General
      keep-open = true;
      save-position-on-quit = true;
      autofit-larger = "90%x90%";
      cursor-autohide = 1000;
    };

    bindings = {
      "l" = "seek 5";
      "h" = "seek -5";
      "j" = "seek -60";
      "k" = "seek 60";
      "S" = "screenshot";
    };
  };
}
