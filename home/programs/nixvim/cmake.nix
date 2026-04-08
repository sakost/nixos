# cmake-tools.nvim — CMake project orchestration (generate / build / run / debug)
#
# Keybindings live under the `<leader>c*` prefix. `<leader>ca` is reserved by
# LSP code-action in lsp.nix:85, so we avoid that single key.
#
# Workflow:
#   1. Open a CMake project
#   2. :CMakeGenerate            (<leader>cg) — writes build/<variant>/ and
#                                 symlinks compile_commands.json to project root
#   3. :CMakeSelectBuildType     (<leader>cv) — Debug / Release / RelWithDebInfo
#   4. :CMakeSelectBuildTarget   (<leader>ct) — pick which target to build
#   5. :CMakeBuild               (<leader>cb) — invoke ninja / make
#   6. :CMakeRun                 (<leader>cr) — run the launch target
#   7. :CMakeDebug               (<leader>cd) — launch under nvim-dap + codelldb
{ ... }:

{
  programs.nixvim.plugins.cmake-tools = {
    enable = true;
    settings = {
      cmake_command = "cmake";
      ctest_command = "ctest";
      cmake_regenerate_on_save = true;

      # Always export compile_commands.json so clangd understands the project.
      cmake_generate_options = {
        "-DCMAKE_EXPORT_COMPILE_COMMANDS" = 1;
      };

      # Per-variant build directory (e.g. build/Debug, build/Release).
      cmake_build_directory = "build/\${variant:buildType}";

      # Symlink compile_commands.json to the project root for clangd.
      cmake_soft_link_compile_commands = true;
      cmake_compile_commands_from_lsp = false;

      # Debug sessions are launched via nvim-dap with the codelldb adapter
      # configured in dap.nix.
      cmake_dap_configuration = {
        name = "cpp";
        type = "codelldb";
        request = "launch";
      };

      # Use the quickfix executor so build errors land in the quickfix list.
      cmake_executor = {
        name = "quickfix";
      };

      # Run targets inside an embedded terminal split.
      cmake_runner = {
        name = "terminal";
      };
    };
  };

  programs.nixvim.keymaps = [
    { mode = "n"; key = "<leader>cg"; action = "<cmd>CMakeGenerate<CR>";        options.desc = "CMake: Generate"; }
    { mode = "n"; key = "<leader>cb"; action = "<cmd>CMakeBuild<CR>";           options.desc = "CMake: Build"; }
    { mode = "n"; key = "<leader>cr"; action = "<cmd>CMakeRun<CR>";             options.desc = "CMake: Run"; }
    { mode = "n"; key = "<leader>cd"; action = "<cmd>CMakeDebug<CR>";           options.desc = "CMake: Debug (DAP)"; }
    { mode = "n"; key = "<leader>cv"; action = "<cmd>CMakeSelectBuildType<CR>"; options.desc = "CMake: Select build type"; }
    { mode = "n"; key = "<leader>ct"; action = "<cmd>CMakeSelectBuildTarget<CR>"; options.desc = "CMake: Select build target"; }
    { mode = "n"; key = "<leader>cl"; action = "<cmd>CMakeSelectLaunchTarget<CR>"; options.desc = "CMake: Select launch target"; }
    { mode = "n"; key = "<leader>ck"; action = "<cmd>CMakeStop<CR>";            options.desc = "CMake: Stop running task"; }
    { mode = "n"; key = "<leader>cC"; action = "<cmd>CMakeClean<CR>";           options.desc = "CMake: Clean"; }
    { mode = "n"; key = "<leader>ci"; action = "<cmd>CMakeInstall<CR>";         options.desc = "CMake: Install"; }
  ];
}
