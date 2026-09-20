# Home-manager configuration for user sakost
{ config, pkgs, inputs, lib, osConfig ? null, ... }:

let
  isServer = osConfig.custom.profiles.server.enable or false;
  tokyonightGtkTheme = pkgs.callPackage ../packages/tokyonight-gtk-theme.nix { };

  commonImports = [
    inputs.nixvim.homeModules.nixvim
    ./xdg.nix
    ./programs/zsh.nix
    ./programs/git.nix
    ./programs/gh.nix
    ./programs/nixvim
    ./programs/cargo-cross.nix
    ./programs/rust.nix
    ./programs/systemctl-tui.nix
    ./programs/starship.nix
    ./programs/atuin.nix
    ./programs/yazi.nix
    ./programs/jupyterlab.nix
    ./programs/gdb.nix
    ./programs/natscli.nix
    ./programs/aws.nix
    ./programs/openssl.nix
    ./programs/xxd.nix
    ./programs/lnav.nix
    ./programs/lftp.nix
    ./programs/tmux.nix
    ./programs/nvtop.nix
    ./programs/onefetch.nix
    ./programs/rtk.nix
    ./programs/codex.nix
    ./programs/openclaude.nix
    ./programs/ffmpeg.nix
  ];

  desktopImports = [
    ./programs/alacritty.nix
    ./programs/walker.nix
    ./programs/gui-apps.nix
    ./programs/waybar.nix
    ./programs/wlogout.nix
    ./programs/hyprlock.nix
    ./programs/steam.nix
    ./programs/swaync.nix
    ./programs/eww.nix
    ./programs/cava.nix
    ./programs/zathura.nix
    ./programs/onlyoffice.nix
    ./programs/obs-studio.nix
    ./programs/mpv.nix
    ./programs/gsimplecal.nix
    ./programs/virt-manager.nix
    ./programs/r2modman.nix
    ./programs/unreal-engine.nix
    ./programs/figma-desktop.nix
    ./programs/pluely.nix
    ./desktop/hyprland
  ];
in
{
  imports = commonImports ++ lib.optionals (!isServer) desktopImports;

  home = {
    username = "sakost";
    homeDirectory = "/home/sakost";
    stateVersion = "25.11";
    # Codex's terminal probe does not tolerate the missing entries in NixOS's
    # generated search path. Restrict it to the concrete ncurses terminfo DB.
    sessionVariables.TERMINFO_DIRS = "${pkgs.ncurses}/share/terminfo";
    packages = with pkgs; [
      inputs.claude-code.packages.x86_64-linux.default
      rustup
      gcc
      pkgsCross.musl64.stdenv.cc
      pkg-config
      # C/C++ toolchain — CMake + Ninja + clangd (LSP & tidy) + LLDB
      # (codelldb DAP adapter is referenced directly from nixvim dap.nix)
      cmake
      ninja
      clang-tools
      lldb
      jq
      just
      ripgrep
      sqlite
      uv
      pandoc
      nodejs-slim
      pnpm
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
      ssh-to-age
      (texliveSmall.withPackages (ps: [
        ps.cyrillic
        ps.babel-russian
        ps.hyphen-russian
      ]))
      mdcat
    ];
  };

  # Install stable Rust toolchain via rustup on activation
  home.activation.rustup = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    export RUSTUP_HOME="${config.xdg.dataHome}/rustup"
    export CARGO_HOME="${config.home.homeDirectory}/dev/cache/cargo"
    run ${pkgs.rustup}/bin/rustup default stable
    run ${pkgs.rustup}/bin/rustup component add rust-analyzer --toolchain stable
  '';

  # Cursor theme — consistent across mixed-DPI monitors
  home.pointerCursor = lib.mkIf (!isServer) {
    enable = true;
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 32;
    gtk.enable = true;
  };

  # GTK theme — TokyoNight Dark to match the rice
  gtk = lib.mkIf (!isServer) {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = tokyonightGtkTheme;
    };
    gtk4.theme = {
      name = "Tokyonight-Dark";
      package = tokyonightGtkTheme;
    };
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # playerctld — manages MPRIS players for media key control
  services.playerctld.enable = lib.mkIf (!isServer) true;

  # GNOME Keyring — secret-service, SSH agent, PKCS#11
  services.gnome-keyring = lib.mkIf (!isServer) {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  # direnv + nix-direnv for auto-activating dev shells
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
