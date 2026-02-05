# Git and GPG agent configuration module
{ config, lib, pkgs, ... }:

{
  # GPG agent with SSH support
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # MTR network diagnostic tool
  programs.mtr.enable = true;
}
