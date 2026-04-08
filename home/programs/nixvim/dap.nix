# nvim-dap — Debug Adapter Protocol client
#
# Adapter: codelldb (from pkgs.vscode-extensions.vadimcn.vscode-lldb).
# Covers both Rust and C++ from a single adapter — LLDB under the hood.
#
# Keybindings under the `<leader>D*` prefix (capital D) to avoid colliding
# with dadbod's lowercase `<leader>db` / `<leader>df` / `<leader>dl`.
# F-keys follow the standard IDE step convention.
#
# Workflow:
#   * <leader>Db — toggle breakpoint on current line
#   * <F5>       — continue (starts the session, then acts as "resume")
#   * <F10>      — step over
#   * <F11>      — step into
#   * <F12>      — step out
#   * <leader>Du — toggle dap-ui side/bottom panels
#   * <leader>Dt — terminate session
#
# For Rust: picks up `target/debug/<crate>` automatically from CWD.
# For C++:  prompts for an executable path (or use :CMakeDebug from cmake-tools).
{ pkgs, ... }:

let
  codelldbAdapter =
    "${pkgs.vscode-extensions.vadimcn.vscode-lldb}/share/vscode/extensions/vadimcn.vscode-lldb/adapter/codelldb";
in
{
  programs.nixvim.plugins.dap = {
    enable = true;

    # Codelldb runs as a TCP server; nvim-dap picks a free port, starts the
    # adapter with `--port <port>`, then connects. The literal "${port}"
    # string is a nvim-dap placeholder — escaped here so nix doesn't try to
    # interpolate it.
    adapters.servers.codelldb = {
      port = "\${port}";
      executable = {
        command = codelldbAdapter;
        args = [ "--port" "\${port}" ];
      };
    };

    # Launch configurations. `cpp` is reused for `c` via a mirrored entry.
    # `rust` auto-suggests `target/debug/<cwd-basename>` as the default path.
    configurations = {
      cpp = [
        {
          name = "Launch C/C++ executable";
          type = "codelldb";
          request = "launch";
          program.__raw = ''
            function()
              return vim.fn.input(
                'Path to executable: ',
                vim.fn.getcwd() .. '/build/',
                'file'
              )
            end
          '';
          cwd = "\${workspaceFolder}";
          stopOnEntry = false;
          args = [ ];
        }
      ];

      c = [
        {
          name = "Launch C executable";
          type = "codelldb";
          request = "launch";
          program.__raw = ''
            function()
              return vim.fn.input(
                'Path to executable: ',
                vim.fn.getcwd() .. '/build/',
                'file'
              )
            end
          '';
          cwd = "\${workspaceFolder}";
          stopOnEntry = false;
          args = [ ];
        }
      ];

      rust = [
        {
          name = "Launch Rust binary";
          type = "codelldb";
          request = "launch";
          program.__raw = ''
            function()
              local cwd = vim.fn.getcwd()
              local crate = vim.fn.fnamemodify(cwd, ':t')
              local default = cwd .. '/target/debug/' .. crate
              return vim.fn.input('Path to executable: ', default, 'file')
            end
          '';
          cwd = "\${workspaceFolder}";
          stopOnEntry = false;
          args = [ ];
          # LLDB can't auto-load Rust's pretty-printers from the toolchain,
          # so nudge it to format types like Vec<T>, String, Option<T>, etc.
          sourceLanguages = [ "rust" ];
        }
      ];
    };

    signs = {
      dapBreakpoint          = { text = "●"; texthl = "DapBreakpoint"; };
      dapBreakpointCondition = { text = "◆"; texthl = "DapBreakpointCondition"; };
      dapLogPoint            = { text = "◆"; texthl = "DapLogPoint"; };
      dapStopped             = { text = "→"; texthl = "DapStopped"; linehl = "DapStoppedLine"; };
      dapBreakpointRejected  = { text = "○"; texthl = "DapBreakpointRejected"; };
    };
  };

  # dap-ui: side panels (scopes, breakpoints, stacks, watches) + bottom repl.
  programs.nixvim.plugins.dap-ui = {
    enable = true;
  };

  # Inline virtual text showing variable values during debugging.
  programs.nixvim.plugins.dap-virtual-text = {
    enable = true;
    settings = {
      enabled = true;
      commented = false;
      all_frames = false;
      virt_text_pos = "eol";
    };
  };

  # Auto-open/close dap-ui when a session starts and ends.
  programs.nixvim.extraConfigLua = ''
    do
      local ok_dap, dap = pcall(require, "dap")
      local ok_dapui, dapui = pcall(require, "dapui")
      if ok_dap and ok_dapui then
        dap.listeners.after.event_initialized["dapui_config"] = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated["dapui_config"] = function()
          dapui.close()
        end
        dap.listeners.before.event_exited["dapui_config"] = function()
          dapui.close()
        end
      end
    end
  '';

  programs.nixvim.keymaps = [
    # --- Step / run control (F-keys, standard IDE convention) ---
    { mode = "n"; key = "<F5>";  action.__raw = "function() require('dap').continue() end";   options.desc = "DAP: Continue / Start"; }
    { mode = "n"; key = "<F10>"; action.__raw = "function() require('dap').step_over() end";  options.desc = "DAP: Step over"; }
    { mode = "n"; key = "<F11>"; action.__raw = "function() require('dap').step_into() end";  options.desc = "DAP: Step into"; }
    { mode = "n"; key = "<F12>"; action.__raw = "function() require('dap').step_out() end";   options.desc = "DAP: Step out"; }

    # --- Leader-prefixed (capital D to avoid dadbod's `<leader>d*`) ---
    { mode = "n"; key = "<leader>Db"; action.__raw = "function() require('dap').toggle_breakpoint() end"; options.desc = "DAP: Toggle breakpoint"; }
    { mode = "n"; key = "<leader>DB"; action.__raw = ''
        function()
          require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))
        end
      ''; options.desc = "DAP: Conditional breakpoint"; }
    { mode = "n"; key = "<leader>Dl"; action.__raw = ''
        function()
          require('dap').set_breakpoint(nil, nil, vim.fn.input('Log message: '))
        end
      ''; options.desc = "DAP: Log point"; }
    { mode = "n"; key = "<leader>Dc"; action.__raw = "function() require('dap').continue() end";           options.desc = "DAP: Continue"; }
    { mode = "n"; key = "<leader>Dr"; action.__raw = "function() require('dap').repl.toggle() end";        options.desc = "DAP: Toggle REPL"; }
    { mode = "n"; key = "<leader>DL"; action.__raw = "function() require('dap').run_last() end";           options.desc = "DAP: Run last"; }
    { mode = "n"; key = "<leader>Dt"; action.__raw = "function() require('dap').terminate() end";          options.desc = "DAP: Terminate"; }
    { mode = "n"; key = "<leader>Du"; action.__raw = "function() require('dapui').toggle() end";           options.desc = "DAP: Toggle UI"; }
    # Hover inspector: shows the value under the cursor in a floating panel
    # during a live session. Uses dap.ui.widgets (the preferred API).
    { mode = "n"; key = "<leader>Dk"; action.__raw = "function() require('dap.ui.widgets').hover() end";   options.desc = "DAP: Inspect value under cursor"; }
    { mode = "n"; key = "<leader>Dp"; action.__raw = "function() require('dap.ui.widgets').preview() end"; options.desc = "DAP: Preview in split"; }
  ];
}
