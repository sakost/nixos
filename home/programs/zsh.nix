# Zsh user configuration
{ config, pkgs, ... }:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "${pkgs.fd}/bin/fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [ "--preview '${pkgs.eza}/bin/eza --tree --level=2 --icons --color=always {}'" ];
    fileWidgetOptions = [ "--preview '${pkgs.bat}/bin/bat --color=always --style=numbers --line-range=:200 {}'" ];
    colors = {
      "bg+" = "#283457";
      bg = "#1a1b26";
      spinner = "#7dcfff";
      hl = "#7aa2f7";
      fg = "#c0caf5";
      header = "#7aa2f7";
      info = "#e0af68";
      pointer = "#7dcfff";
      marker = "#9ece6a";
      "fg+" = "#c0caf5";
      prompt = "#7aa2f7";
      "hl+" = "#7aa2f7";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "tokyonight_night";
    };
    themes = {
      tokyonight_night = {
        src = pkgs.fetchFromGitHub {
          owner = "folke";
          repo = "tokyonight.nvim";
          rev = "v4.8.0";
          hash = "sha256-5QeY3EevOQzz5PHDW2CUVJ7N42TRQdh7QOF9PH1YxkU=";
        };
        file = "extras/sublime/tokyonight_night.tmTheme";
      };
    };
  };

  programs.zsh = {
    enable = true;

    shellAliases = {
      # NixOS rebuild shortcuts (config in home directory)
      nrs = "sudo nixos-rebuild switch --flake ~/nixos-config";
      nrb = "sudo nixos-rebuild build --flake ~/nixos-config";
      nrt = "sudo nixos-rebuild test --flake ~/nixos-config";

      # Editor shortcuts
      ne = "nvim ~/nixos-config";
      svim = "sudo nvim";

      # Python
      python = "python3";

      # eza replacements
      ll = "eza -la";
      la = "eza -a";
      l = "eza -l";
      lt = "eza --tree --level=2";

      # bat
      cat = "bat";

      # misc
      cl = "clear";
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Completion styling (interactive menu that clears properly on cancel)
    # Zoxide interactive preview (eza tree in fzf panel)
    initContent = ''
      zmodload zsh/complist
      zstyle ':completion:*' menu select
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

      export _ZO_FZF_OPTS="--preview '${pkgs.eza}/bin/eza --tree --level=2 --icons --color=always {2..}'"

      # Ensure atuin owns Ctrl+R (fzf may bind it depending on init order)
      bindkey '^R' atuin-search

      # Ctrl+L to clear screen
      bindkey '^L' clear-screen
    '';

    history = {
      append = true;         # Append on exit rather than overwrite
      save = 10000;
      size = 10000;
      share = false;         # Don't share history between terminals in real-time
    };

    dotDir = "${config.xdg.configHome}/zsh";
  };
}
