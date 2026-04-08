# Nixvim LSP configuration
{ ... }:

{
  programs.nixvim.plugins.lsp = {
    enable = true;

    servers = {
      # Python — detect venv via uv or VIRTUAL_ENV
      pyright = {
        enable = true;
        extraOptions.before_init = {
          __raw = ''
            function(_, config)
              local root = config.root_dir or vim.fn.getcwd()
              -- Detect Python from uv project
              if vim.fn.filereadable(root .. '/pyproject.toml') == 1 then
                local py = vim.fn.trim(vim.fn.system({
                  'uv', 'run', '--no-sync', '--project', root, 'which', 'python'
                }))
                if vim.v.shell_error == 0 and py ~= "" and vim.fn.filereadable(py) == 1 then
                  config.settings.python = config.settings.python or {}
                  config.settings.python.pythonPath = py
                  return
                end
              end
              -- Fallback: active virtualenv
              local venv = os.getenv('VIRTUAL_ENV')
              if venv and vim.fn.isdirectory(venv) == 1 then
                config.settings.python = config.settings.python or {}
                config.settings.python.pythonPath = venv .. '/bin/python'
              end
            end
          '';
        };
      };

      # Rust
      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
      };

      # C/C++ — clangd. Uses compile_commands.json which cmake-tools.nvim
      # auto-symlinks to the project root after :CMakeGenerate.
      clangd = {
        enable = true;
        # Disable lsp-format's auto-format for clangd — clang-format runs
        # via the clangd LSP formatter and we bind it to <leader>f manually.
        extraOptions.capabilities = {
          offsetEncoding = [ "utf-16" ];
        };
      };

      # TypeScript/JavaScript
      ts_ls.enable = true;

      # Nix
      nil_ls.enable = true;

      # Lua
      lua_ls = {
        enable = true;
        settings.Lua = {
          diagnostics.globals = [ "vim" ];
          workspace.checkThirdParty = false;
        };
      };

      # Go
      gopls.enable = true;

      # Bash
      bashls.enable = true;

      # JSON
      jsonls.enable = true;

      # YAML
      yamlls.enable = true;

      # TOML
      taplo.enable = true;

      # HTML/CSS
      html.enable = true;
      cssls.enable = true;

      # Protobuf
      buf_ls.enable = true;
    };

    keymaps = {
      lspBuf = {
        "gd" = "definition";
        "gD" = "declaration";
        "gr" = "references";
        "gi" = "implementation";
        "gt" = "type_definition";
        "K" = "hover";
        "<leader>rn" = "rename";
        "<leader>ca" = "code_action";
        "<leader>f" = "format";
      };
      diagnostic = {
        "<leader>e" = "open_float";
        "[d" = "goto_prev";
        "]d" = "goto_next";
      };
    };
  };

  # Format on save — modern LspAttach pattern using vim.lsp.buf.format directly.
  # Replaces lsp-format.nvim, which called the deprecated dot-syntax
  # `client.supports_method(...)` on every save and spammed
  # "client.supports_method is deprecated" warnings in Neovim 0.11+.
  #
  # How it works:
  #   1. When an LSP client attaches to a buffer (LspAttach), check whether
  #      it supports textDocument/formatting via the new colon-syntax
  #      `client:supports_method(...)` API.
  #   2. If yes, install a *buffer-local* BufWritePre autocmd that formats
  #      that buffer. Buffer-local autocmds auto-clean when the buffer closes.
  #   3. The format call is pinned to `id = client.id` so exactly one client
  #      formats the buffer, avoiding fighting between e.g. null-ls and LSP.
  programs.nixvim.extraConfigLua = ''
    do
      local fmt_group = vim.api.nvim_create_augroup("LspFormatOnSave", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = fmt_group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
              group = fmt_group,
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({
                  async = false,
                  bufnr = args.buf,
                  id = client.id,
                  timeout_ms = 2000,
                })
              end,
            })
          end
        end,
      })
    end
  '';

  # clangd-extensions: inlay hints, AST viewer, memory usage, symbol info
  programs.nixvim.plugins.clangd-extensions = {
    enable = true;
    enableOffsetEncodingWorkaround = true;
  };
}
