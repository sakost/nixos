# ffmpeg — full build (every codec/library compiled in: fdk-aac, NDI, frei0r,
# OpenCL, ...). Worth the extra closure size on a desktop that already runs
# OBS/mpv since plain `pkgs.ffmpeg` lacks common codecs.
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.ffmpeg-full ];
}
