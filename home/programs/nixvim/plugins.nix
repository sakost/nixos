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
          "proto"
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
        noautocmd = true;
        condition = ''
          function(buf)
            local ft = vim.bo[buf].filetype
            local bt = vim.bo[buf].buftype
            if ft == "dbui" or ft == "dbout" or bt == "terminal" or bt == "nofile" and ft == "sql" then
              return false
            end
            return true
          end
        '';
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
        rev = "v0.3.0";
        hash = "sha256-sOBY2y/buInf+SxLwz6uYlUouDULwebY/nmDlbFbGa8=";
      };
    })
  ];

  programs.nixvim.extraConfigLua = ''
    require("claudecode").setup({
      auto_start = true,
      terminal = {
        split_side = "right",
        split_width_percentage = 0.30,
        provider = "snacks",
      },
      diff_opts = {
        auto_close_on_accept = true,
        vertical_split = true,
      },
    })
  '';

  # Plugin keymaps
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>xx"; action = ":Trouble diagnostics toggle<CR>"; options.desc = "Toggle Trouble"; }
    { mode = "n"; key = "<leader>xd"; action = ":Trouble diagnostics toggle filter.buf=0<CR>"; options.desc = "Buffer diagnostics"; }
    { mode = "n"; key = "<leader>mp"; action = ":MarkdownPreview<CR>"; options.desc = "Markdown preview"; }

    # Claude Code
    { mode = "n"; key = "<leader>ac"; action = "<cmd>ClaudeCode<CR>"; options.desc = "Toggle Claude"; }
    { mode = "n"; key = "<leader>af"; action = "<cmd>ClaudeCodeFocus<CR>"; options.desc = "Focus Claude"; }
    { mode = "n"; key = "<leader>ar"; action = "<cmd>ClaudeCode --resume<CR>"; options.desc = "Resume Claude"; }
    { mode = "n"; key = "<leader>aC"; action = "<cmd>ClaudeCode --continue<CR>"; options.desc = "Continue Claude"; }
    { mode = "n"; key = "<leader>am"; action = "<cmd>ClaudeCodeSelectModel<CR>"; options.desc = "Select model"; }
    { mode = "n"; key = "<leader>ab"; action = "<cmd>ClaudeCodeAdd %<CR>"; options.desc = "Add current buffer"; }
    { mode = "v"; key = "<leader>as"; action = "<cmd>ClaudeCodeSend<CR>"; options.desc = "Send selection to Claude"; }
    { mode = "n"; key = "<leader>aa"; action = "<cmd>ClaudeCodeDiffAccept<CR>"; options.desc = "Accept diff"; }
    { mode = "n"; key = "<leader>ad"; action = "<cmd>ClaudeCodeDiffDeny<CR>"; options.desc = "Deny diff"; }
  ];
}
