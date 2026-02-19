# GDB configuration
{ config, pkgs, ... }:

{
  home.packages = [ pkgs.gdb ];

  home.file.".gdbinit".text = ''
    set history save on
    set history filename ${config.xdg.dataHome}/gdb/history
    set disassembly-flavor intel
    set print pretty on
  '';
}
