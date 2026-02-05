# Nixvim keymaps
{ ... }:

{
  programs.nixvim.keymaps = [
    # Better window navigation
    { mode = "n"; key = "<C-h>"; action = "<C-w>h"; options.desc = "Move to left window"; }
    { mode = "n"; key = "<C-j>"; action = "<C-w>j"; options.desc = "Move to lower window"; }
    { mode = "n"; key = "<C-k>"; action = "<C-w>k"; options.desc = "Move to upper window"; }
    { mode = "n"; key = "<C-l>"; action = "<C-w>l"; options.desc = "Move to right window"; }

    # Resize windows
    { mode = "n"; key = "<C-Up>"; action = ":resize -2<CR>"; options.desc = "Decrease height"; }
    { mode = "n"; key = "<C-Down>"; action = ":resize +2<CR>"; options.desc = "Increase height"; }
    { mode = "n"; key = "<C-Left>"; action = ":vertical resize -2<CR>"; options.desc = "Decrease width"; }
    { mode = "n"; key = "<C-Right>"; action = ":vertical resize +2<CR>"; options.desc = "Increase width"; }

    # Buffer navigation
    { mode = "n"; key = "<S-l>"; action = ":bnext<CR>"; options.desc = "Next buffer"; }
    { mode = "n"; key = "<S-h>"; action = ":bprevious<CR>"; options.desc = "Previous buffer"; }
    { mode = "n"; key = "<leader>bd"; action = ":bdelete<CR>"; options.desc = "Delete buffer"; }

    # Clear search highlight
    { mode = "n"; key = "<Esc>"; action = ":nohlsearch<CR>"; options.desc = "Clear search highlight"; }

    # Better indenting in visual mode
    { mode = "v"; key = "<"; action = "<gv"; options.desc = "Indent left"; }
    { mode = "v"; key = ">"; action = ">gv"; options.desc = "Indent right"; }

    # Move lines up/down
    { mode = "n"; key = "<A-j>"; action = ":m .+1<CR>=="; options.desc = "Move line down"; }
    { mode = "n"; key = "<A-k>"; action = ":m .-2<CR>=="; options.desc = "Move line up"; }
    { mode = "v"; key = "<A-j>"; action = ":m '>+1<CR>gv=gv"; options.desc = "Move selection down"; }
    { mode = "v"; key = "<A-k>"; action = ":m '<-2<CR>gv=gv"; options.desc = "Move selection up"; }

    # Save file
    { mode = "n"; key = "<C-s>"; action = ":w<CR>"; options.desc = "Save file"; }
    { mode = "i"; key = "<C-s>"; action = "<Esc>:w<CR>"; options.desc = "Save file"; }

    # Quit
    { mode = "n"; key = "<leader>q"; action = ":q<CR>"; options.desc = "Quit"; }
    { mode = "n"; key = "<leader>Q"; action = ":qa!<CR>"; options.desc = "Quit all"; }
  ];
}
