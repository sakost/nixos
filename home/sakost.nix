# Home-manager configuration for user sakost
{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./xdg.nix
    ./programs/zsh.nix
    ./programs/alacritty.nix
    ./programs/walker.nix
    ./programs/gui-apps.nix
    ./programs/waybar.nix
    ./programs/wlogout.nix
    ./programs/git.nix
    ./programs/gh.nix
    ./programs/nixvim
    ./programs/cargo-cross.nix
    ./programs/flutter.nix
    ./programs/steam.nix
    ./programs/wallpaper-engine.nix
    ./programs/mako.nix
    ./programs/eww.nix
    ./programs/starship.nix
    ./programs/atuin.nix
    ./programs/yazi.nix
    ./programs/zathura.nix
    ./programs/onlyoffice.nix
    ./programs/gdb.nix
    ./programs/ollama.nix
    ./programs/obs-studio.nix
    ./programs/natscli.nix
    ./programs/openssl.nix
    ./programs/xxd.nix
    ./desktop/hyprland.nix
  ];

  home = {
    username = "sakost";
    homeDirectory = "/home/sakost";
    stateVersion = "25.11";
    packages = with pkgs; [
      inputs.claude-code.packages.x86_64-linux.default
      rustup
      gcc
      pkgsCross.musl64.stdenv.cc
      pkg-config
      jq
      just
      ripgrep
      sqlite
      uv
      nodejs
      yarn
      cargo-deny
      btop
      fastfetch
      gnumake
      go
      go-task
      glab
      postgresql
      (google-cloud-sdk.withExtraComponents [
        google-cloud-sdk.components.gke-gcloud-auth-plugin
      ])
      google-cloud-sql-proxy
      argocd
      fluxcd
      kubectl
      kubectl-cnpg
      kubeseal
      kubie
      helmfile
      kubernetes-helm
      kustomize
      velero
      python3
      protobuf
      buf
      zip
      unzip
      libsecret
      tldr
      fd
    ];
  };

  # Install stable Rust toolchain via rustup on activation
  home.activation.rustup = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export RUSTUP_HOME="${config.xdg.dataHome}/rustup"
    export CARGO_HOME="${config.home.homeDirectory}/dev/cache/cargo"
    run ${pkgs.rustup}/bin/rustup default stable
  '';

  # Cursor theme — consistent across mixed-DPI monitors
  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 32;
    gtk.enable = true;
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # playerctld — manages MPRIS players for media key control
  services.playerctld.enable = true;

  # GNOME Keyring — secret-service, SSH agent, PKCS#11
  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # direnv + nix-direnv for auto-activating dev shells
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
