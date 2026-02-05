# Nixvim editor options
{ ... }:

{
  programs.nixvim = {
    opts = {
      # Line numbers
      number = true;
      relativenumber = true;

      # Clipboard integration
      clipboard = "unnamedplus";

      # Indentation
      shiftwidth = 2;
      tabstop = 2;
      softtabstop = 2;
      expandtab = true;
      smartindent = true;

      # Search
      ignorecase = true;
      smartcase = true;
      hlsearch = true;
      incsearch = true;

      # UI
      termguicolors = true;
      signcolumn = "yes";
      cursorline = true;
      scrolloff = 8;
      sidescrolloff = 8;

      # Files
      swapfile = false;
      backup = false;
      undofile = true;

      # Performance
      updatetime = 250;
      timeoutlen = 300;

      # Split behavior
      splitright = true;
      splitbelow = true;
    };

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };
  };
}
