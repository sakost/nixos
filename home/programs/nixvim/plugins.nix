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

    # Snacks.nvim (required by claudecode.nvim, also provides terminal)
    snacks = {
      enable = true;
      settings.terminal = {
        win = {
          style = "terminal";
        };
      };
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

  # claudecode.nvim - Claude Code integration (pinned to main for post-v0.3.0 fixes)
  programs.nixvim.extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      name = "claudecode-nvim";
      src = pkgs.fetchFromGitHub {
        owner = "coder";
        repo = "claudecode.nvim";
        rev = "432121f0f5b9bda041030d1e9e83b7ba3a93dd8f";
        hash = "sha256-r8hAUpSsr8zNm+av8Mu5oILaTfEsXEnJmkzRmvi9pF8=";
      };
    })
  ];

  programs.nixvim.extraConfigLua = ''
    -- :Pandoc <format> — convert current Markdown file (e.g. :Pandoc html, :Pandoc pdf)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        vim.api.nvim_buf_create_user_command(0, "Pandoc", function(args)
          local fmt = args.args
          local extra = ""
          if fmt == "pdf" then
            extra = " --pdf-engine=xelatex"
          end
          vim.cmd(
            "!pandoc -i "
              .. vim.fn.fnameescape(vim.fn.expand("%"))
              .. " -o "
              .. vim.fn.fnameescape(vim.fn.expand("%:r") .. "." .. fmt)
              .. extra
          )
        end, { nargs = 1 })
      end,
    })

    require("claudecode").setup({
      auto_start = true,
      track_selection = true,

      terminal = {
        split_side = "right",
        split_width_percentage = 0.30,
        provider = "snacks",
        auto_close = true,
        -- Ctrl+, toggles a floating overlay (alternative to side split)
        snacks_win_opts = {
          position = "float",
          width = 0.85,
          height = 0.85,
          keys = {
            claude_hide = {
              "<C-,>",
              function(self) self:hide() end,
              mode = "t",
              desc = "Hide Claude float",
            },
          },
        },
      },

      diff_opts = {
        auto_close_on_accept = true,
        vertical_split = true,
        open_in_current_tab = true,
        show_diff_stats = true,
        keep_terminal_focus = false,
      },
    })
  '';

  # Plugin keymaps
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>xx"; action = ":Trouble diagnostics toggle<CR>"; options.desc = "Toggle Trouble"; }
    { mode = "n"; key = "<leader>xd"; action = ":Trouble diagnostics toggle filter.buf=0<CR>"; options.desc = "Buffer diagnostics"; }
    { mode = "n"; key = "<leader>mp"; action = ":MarkdownPreview<CR>"; options.desc = "Markdown preview"; }

    # Snacks terminal — suppressed inside NvimTree so <C-/> in the file
    # explorer doesn't steal focus or spawn a split under the tree column.
    { mode = "n"; key = "<C-/>"; action.__raw = ''
        function()
          if vim.bo.filetype == "NvimTree" then return end
          Snacks.terminal.toggle()
        end
      ''; options.desc = "Toggle terminal (no-op in NvimTree)"; }
    { mode = "t"; key = "<C-/>"; action.__raw = "function() Snacks.terminal.toggle() end"; options.desc = "Hide terminal"; }

    # Claude Code
    { mode = "n"; key = "<leader>ac"; action = "<cmd>ClaudeCode<CR>"; options.desc = "Toggle Claude"; }
    { mode = "n"; key = "<leader>af"; action = "<cmd>ClaudeCodeFocus<CR>"; options.desc = "Focus Claude"; }
    { mode = ["n" "x"]; key = "<C-,>"; action = "<cmd>ClaudeCodeFocus<CR>"; options.desc = "Toggle Claude float"; }
    { mode = "n"; key = "<leader>ar"; action = "<cmd>ClaudeCode --resume<CR>"; options.desc = "Resume Claude"; }
    { mode = "n"; key = "<leader>aC"; action = "<cmd>ClaudeCode --continue<CR>"; options.desc = "Continue Claude"; }
    { mode = "n"; key = "<leader>am"; action = "<cmd>ClaudeCodeSelectModel<CR>"; options.desc = "Select model"; }
    { mode = "n"; key = "<leader>ab"; action = "<cmd>ClaudeCodeAdd %<CR>"; options.desc = "Add current buffer"; }
    { mode = "n"; key = "<leader>at"; action = "<cmd>ClaudeCodeTreeAdd<CR>"; options.desc = "Add tree selection"; }
    { mode = "v"; key = "<leader>as"; action = "<cmd>ClaudeCodeSend<CR>"; options.desc = "Send selection to Claude"; }
    { mode = "n"; key = "<leader>aa"; action = "<cmd>ClaudeCodeDiffAccept<CR>"; options.desc = "Accept diff"; }
    { mode = "n"; key = "<leader>ad"; action = "<cmd>ClaudeCodeDiffDeny<CR>"; options.desc = "Deny diff"; }
    { mode = "n"; key = "<leader>aS"; action = "<cmd>ClaudeCodeStatus<CR>"; options.desc = "Claude status"; }
  ];
}
