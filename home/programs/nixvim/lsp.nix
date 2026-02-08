# Nixvim LSP configuration
{ ... }:

{
  programs.nixvim.plugins.lsp = {
    enable = true;

    servers = {
      # Python
      pyright.enable = true;

      # Rust
      rust_analyzer = {
        enable = true;
        installCargo = true;
        installRustc = true;
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
}
