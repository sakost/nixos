# Home-manager configuration for user sakost
{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./xdg.nix
    ./programs/zsh.nix
    ./programs/alacritty.nix
    ./programs/rofi.nix
    ./programs/gui-apps.nix
    ./programs/waybar.nix
    ./programs/git.nix
    ./programs/nixvim
    ./desktop/hyprland.nix
  ];

  home = {
    username = "sakost";
    homeDirectory = "/home/sakost";
    stateVersion = "25.11";
    packages = with pkgs; [
      inputs.claude-code.packages.x86_64-linux.default
      rustup
      ripgrep
      zoxide
      uv
      nodejs
      yarn
    ];
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # direnv + nix-direnv for auto-activating dev shells
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
