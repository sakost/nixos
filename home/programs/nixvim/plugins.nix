# Nixvim additional plugins
{ pkgs, ... }:

{
  programs.nixvim.plugins = {
    # Syntax highlighting
    treesitter = {
      enable = true;

      settings = {
        highlight.enable = true;
        indent.enable = true;

        ensure_installed = [
          "bash"
          "c"
          "cpp"
          "css"
          "dockerfile"
          "go"
          "html"
          "javascript"
          "json"
          "lua"
          "markdown"
          "markdown_inline"
          "nix"
          "python"
          "rust"
          "toml"
          "tsx"
          "typescript"
          "vim"
          "vimdoc"
          "yaml"
        ];
      };
    };

    # Auto pairs
    nvim-autopairs = {
      enable = true;
      settings = {
        check_ts = true;
      };
    };

    # Comment toggling
    comment = {
      enable = true;
    };

    # Surround
    nvim-surround.enable = true;

    # Better escape (jk to escape insert mode)
    better-escape = {
      enable = true;
      settings = {
        timeout = 200;
        mappings = {
          i.j.k = "<Esc>";
        };
      };
    };

    # Auto-save
    auto-save = {
      enable = true;
      settings = {
        enabled = true;
        trigger_events = {
          immediate_save = [ "BufLeave" "FocusLost" ];
          defer_save = [ "InsertLeave" "TextChanged" ];
        };
        debounce_delay = 1000;
      };
    };

    # Todo comments highlighting
    todo-comments = {
      enable = true;
      settings = {
        signs = true;
        highlight = {
          pattern = ".*<(KEYWORDS)\\s*:";
        };
      };
    };

    # Trouble (diagnostics list)
    trouble = {
      enable = true;
    };

    # Snacks.nvim (required by claudecode.nvim)
    snacks = {
      enable = true;
    };

    # Markdown preview
    markdown-preview = {
      enable = true;
      settings = {
        auto_start = 0;
        browser = "google-chrome";
      };
    };
  };

  # claudecode.nvim - Claude Code integration
  programs.nixvim.extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "claudecode-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "coder";
        repo = "claudecode.nvim";
        rev = "aa9a5cebebdbfa449c1c5ff229ba5d98e66bafed";
        hash = "sha256-B6BA+3h7RLmk+zk6O365DmY06ALdbbkFBmOaRH9muog=";
      };
    })
  ];

  programs.nixvim.extraConfigLua = ''
    require("claudecode").setup()
  '';

  # Plugin keymaps
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>xx"; action = ":Trouble diagnostics toggle<CR>"; options.desc = "Toggle Trouble"; }
    { mode = "n"; key = "<leader>xd"; action = ":Trouble diagnostics toggle filter.buf=0<CR>"; options.desc = "Buffer diagnostics"; }
    { mode = "n"; key = "<leader>mp"; action = ":MarkdownPreview<CR>"; options.desc = "Markdown preview"; }
  ];
}
