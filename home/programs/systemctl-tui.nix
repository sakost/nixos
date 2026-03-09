# systemctl-tui — TUI for managing systemd services (system & user)
{ pkgs, ... }:

{
  home.packages = [ pkgs.systemctl-tui ];
}
