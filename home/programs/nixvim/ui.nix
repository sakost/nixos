# Nixvim UI plugins (nvim-tree, lualine, bufferline, etc.)
{ ... }:

{
  programs.nixvim.plugins = {
    # File explorer
    nvim-tree = {
      enable = true;
      openOnSetup = true;
      autoReloadOnWrite = true;

      diagnostics.enable = true;

      view = {
        width = 30;
        side = "left";
      };

      renderer = {
        highlightGit = true;
        icons.show = {
          git = true;
          folder = true;
          file = true;
        };
      };

      filters = {
        dotfiles = false;
        custom = [ ".git" "node_modules" ".cache" "__pycache__" ];
      };
    };

    # Status line
    lualine = {
      enable = true;

      settings = {
        options = {
          theme = "auto";
          globalstatus = true;
          component_separators = { left = ""; right = ""; };
          section_separators = { left = ""; right = ""; };
        };

        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [ "branch" "diff" "diagnostics" ];
          lualine_c = [ "filename" ];
          lualine_x = [ "encoding" "fileformat" "filetype" ];
          lualine_y = [ "progress" ];
          lualine_z = [ "location" ];
        };
      };
    };

    # Buffer line (tabs)
    bufferline = {
      enable = true;
      settings.options = {
        mode = "buffers";
        diagnostics = "nvim_lsp";
        offsets = [
          {
            filetype = "NvimTree";
            text = "File Explorer";
            highlight = "Directory";
            separator = true;
          }
        ];
      };
    };

    # Icons
    web-devicons.enable = true;

    # Indent guides
    indent-blankline = {
      enable = true;
      settings = {
        indent.char = "│";
        scope.enabled = true;
      };
    };

    # Which-key for keybinding hints
    which-key = {
      enable = true;
      settings = {
        delay = 200;
      };
    };

    # Colorscheme
    tokyonight = {
      enable = true;
      settings = {
        style = "night";
        transparent = true;
      };
    };
  };

  # Set colorscheme
  programs.nixvim.colorscheme = "tokyonight";

  # Keymaps for UI plugins
  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>e"; action = ":NvimTreeToggle<CR>"; options.desc = "Toggle file explorer"; }
    { mode = "n"; key = "<leader>o"; action = ":NvimTreeFocus<CR>"; options.desc = "Focus file explorer"; }
  ];
}
