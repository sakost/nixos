# AI ghost-text inline completion via llama.vim.
#
# Talks to the local llama-swap proxy (see home/programs/llama-completion.nix),
# which lazy-loads Qwen2.5-Coder-7B. Coexists with nvim-cmp; the cmp <Tab>
# mapping (in completion.nix) is responsible for accepting a shown suggestion
# via llama#fim_accept('full').
#
# llama.vim binds its accept keys buffer-locally (inoremap) only while a hint
# is shown; its defaults are <Tab> (accept_full) and <S-Tab> (accept_line),
# which would shadow cmp. We relocate them into the plugin's own <leader>ll*
# namespace so cmp keeps sole ownership of <Tab>/<S-Tab>.
{ pkgs, llamaCompletion, ... }:

let
  endpointFim = "http://127.0.0.1:${toString llamaCompletion.proxyPort}/upstream/${llamaCompletion.modelId}/infill";
in
{
  programs.nixvim = {
    extraPlugins = [ pkgs.vimPlugins.llama-vim ];

    # g:llama_config is merged over the plugin's internal defaults, so we set
    # only what we change. endpoint_fim routes through llama-swap; the accept
    # keys move off <Tab>/<S-Tab>.
    globals.llama_config = {
      endpoint_fim = endpointFim;
      keymap_fim_accept_full = "<leader>lla";
      keymap_fim_accept_line = "<leader>llL";
      # keymap_fim_accept_word keeps its default <leader>ll]
      auto_fim = true;
      show_info = 0;  # no inline perf stats; keep ghost text clean
    };
  };
}
