# Zsh user configuration
{ config, pkgs, ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" "history" ];
      theme = "agnoster";
    };

    shellAliases = {
      # NixOS rebuild shortcuts (config in home directory)
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config";
      nrb = "sudo nixos-rebuild build --flake ~/nixos-config";
      nrt = "sudo nixos-rebuild test --flake ~/nixos-config";

      # Editor shortcuts
      ne = "nvim ~/nixos-config";
      svim = "sudo nvim";

      # Common shortcuts
      ll = "ls -la";
      la = "ls -A";
      l = "ls -CF";
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    dotDir = "${config.xdg.configHome}/zsh";
  };
}
