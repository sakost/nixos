# Nixvim vim-dadbod configuration - Database client
{ ... }:

{
  programs.nixvim.plugins = {
    vim-dadbod.enable = true;
    vim-dadbod-ui.enable = true;
    vim-dadbod-completion.enable = true;
  };

  # dadbod-ui settings
  programs.nixvim.globals = {
    db_ui_use_nerd_fonts = 1;
    db_ui_show_database_icon = 1;
    db_ui_force_echo_notifications = 1;
    db_ui_auto_execute_table_helpers = 1;
  };

  # Add dadbod-completion to cmp sources for SQL filetypes
  programs.nixvim.extraConfigLua = ''
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "sql", "mysql", "plsql" },
      callback = function()
        require("cmp").setup.buffer({
          sources = {
            { name = "vim-dadbod-completion", priority = 1000 },
            { name = "buffer", priority = 500 },
          },
        })
      end,
    })
  '';

  # Keymaps
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>db"; action = "<cmd>DBUIToggle<CR>"; options.desc = "Toggle DB UI"; }
    { mode = "n"; key = "<leader>df"; action = "<cmd>DBUIFindBuffer<CR>"; options.desc = "DB UI find buffer"; }
    { mode = "n"; key = "<leader>dl"; action = "<cmd>DBUILastQueryInfo<CR>"; options.desc = "DB last query info"; }
  ];
}
