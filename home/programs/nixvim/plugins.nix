# Nixvim additional plugins
{ ... }:

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

    # Markdown preview
    markdown-preview = {
      enable = true;
      settings = {
        auto_start = 0;
        browser = "google-chrome";
      };
    };
  };

  # Plugin keymaps
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>xx"; action = ":Trouble diagnostics toggle<CR>"; options.desc = "Toggle Trouble"; }
    { mode = "n"; key = "<leader>xd"; action = ":Trouble diagnostics toggle filter.buf=0<CR>"; options.desc = "Buffer diagnostics"; }
    { mode = "n"; key = "<leader>mp"; action = ":MarkdownPreview<CR>"; options.desc = "Markdown preview"; }
  ];
}
