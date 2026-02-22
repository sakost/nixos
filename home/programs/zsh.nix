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
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
    changeDirWidgetOptions = [ "--preview 'eza --tree --level=2 --icons --color=always {}'" ];
    fileWidgetOptions = [ "--preview 'bat --color=always --style=numbers --line-range=:200 {}'" ];
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

      export _ZO_FZF_OPTS="--preview 'eza --tree --level=2 --icons --color=always {2..}'"
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
