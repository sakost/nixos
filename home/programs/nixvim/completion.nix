# Nixvim completion configuration (nvim-cmp)
{ ... }:

{
  programs.nixvim.plugins = {
    # Main completion engine
    cmp = {
      enable = true;

      settings = {
        snippet.expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
        '';

        mapping = {
          "<C-b>" = "cmp.mapping.scroll_docs(-4)";
          "<C-f>" = "cmp.mapping.scroll_docs(4)";
          "<C-Space>" = "cmp.mapping.complete()";
          "<C-e>" = "cmp.mapping.abort()";
          "<CR>" = "cmp.mapping.confirm({ select = true })";

          # Smart Tab: context-aware cycling.
          #   1. If the cmp popup is visible  → select next completion item
          #   2. Else if AI ghost text (llama.vim) is shown → accept the full suggestion
          #   3. Else if inside an expandable/jumpable snippet → jump to next placeholder
          #      (this is what moves you between template/function arg stops)
          #   4. Otherwise → literal tab (fallback)
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              -- llama#is_fim_hint_shown() returns a Lua boolean on modern nvim
              -- (v:true/v:false) but may be integer 0/1 on others — accept both.
              -- The exists() guard keeps this safe when the plugin isn't loaded.
              local llama_shown = vim.fn.exists('*llama#is_fim_hint_shown') == 1
                  and vim.fn['llama#is_fim_hint_shown']()
              if cmp.visible() then
                cmp.select_next_item()
              elseif llama_shown == true or llama_shown == 1 then
                -- AI ghost text is showing and the cmp menu is not — accept it.
                vim.fn['llama#fim_accept']('full')
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' })
          '';

          # Smart Shift-Tab: mirror of the above, backward direction.
          "<S-Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' })
          '';

          # Dedicated explicit jumps — useful if Tab is already consumed by
          # something else (e.g. inside a terminal-in-buffer) or if you want
          # to jump without closing the completion popup.
          "<C-l>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              if luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' })
          '';
          "<C-h>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              if luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { 'i', 's' })
          '';
        };

        sources = [
          { name = "nvim_lsp"; priority = 1000; }
          { name = "luasnip"; priority = 750; }
          { name = "buffer"; priority = 500; }
          { name = "path"; priority = 250; }
        ];
      };
    };

    # Completion sources
    cmp-nvim-lsp.enable = true;
    cmp-buffer.enable = true;
    cmp-path.enable = true;
    cmp_luasnip.enable = true;

    # Snippet engine
    luasnip = {
      enable = true;
      settings = {
        enable_autosnippets = true;
        store_selection_keys = "<Tab>";
      };
    };

    # Friendly snippets collection
    friendly-snippets.enable = true;
  };
}
