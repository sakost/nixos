# Nixvim Telescope configuration (fuzzy finder)
{ ... }:

{
  programs.nixvim.plugins.telescope = {
    enable = true;

    settings = {
      defaults = {
        file_ignore_patterns = [
          "^.git/"
          "node_modules"
          "__pycache__"
          "%.lock"
          "target/"
        ];
        layout_strategy = "horizontal";
        layout_config = {
          horizontal = {
            preview_width = 0.55;
          };
        };
      };
    };

    extensions = {
      fzf-native.enable = true;
      ui-select.enable = true;
    };

    keymaps = {
      # File pickers
      "<leader>ff" = {
        action = "find_files";
        options.desc = "Find files";
      };
      "<leader>fg" = {
        action = "live_grep";
        options.desc = "Live grep";
      };
      "<leader>fb" = {
        action = "buffers";
        options.desc = "Find buffers";
      };
      "<leader>fh" = {
        action = "help_tags";
        options.desc = "Help tags";
      };
      "<leader>fr" = {
        action = "oldfiles";
        options.desc = "Recent files";
      };

      # Git pickers
      "<leader>gc" = {
        action = "git_commits";
        options.desc = "Git commits";
      };
      "<leader>gs" = {
        action = "git_status";
        options.desc = "Git status";
      };

      # LSP pickers
      "<leader>ls" = {
        action = "lsp_document_symbols";
        options.desc = "Document symbols";
      };
      "<leader>lw" = {
        action = "lsp_workspace_symbols";
        options.desc = "Workspace symbols";
      };
      "<leader>ld" = {
        action = "diagnostics";
        options.desc = "Diagnostics";
      };
    };
  };
}
