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

  # Format on save
  programs.nixvim.plugins.lsp-format = {
    enable = true;
  };

  # clangd-extensions: inlay hints, AST viewer, memory usage, symbol info
  programs.nixvim.plugins.clangd-extensions = {
    enable = true;
    enableOffsetEncodingWorkaround = true;
  };
}
