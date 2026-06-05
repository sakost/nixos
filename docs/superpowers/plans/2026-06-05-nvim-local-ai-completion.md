# Local AI inline completion for Neovim — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add JetBrains-style, fully-offline, AI ghost-text completion to nixvim — a single local `Qwen2.5-Coder-7B` model served on the RTX 4080, shared across all Neovim instances, loaded on demand and freed when idle, accepted with `<Tab>` alongside the existing nvim-cmp popup.

**Architecture:** A `llama-swap` systemd **user** service (always listening on `127.0.0.1:8080`, ~0 VRAM idle) lazy-loads a CUDA `llama-server` running a Nix-store-pinned GGUF on the first `/infill` request and unloads it after a 10-min idle TTL. The `llama.vim` plugin in every nvim instance points at the same proxy endpoint, giving a shared model. A 4-way `<Tab>` handler in cmp arbitrates between the cmp popup, the AI ghost text, snippet jumps, and a literal tab.

**Tech Stack:** Nix (home-manager), `llama-cpp` (CUDA), `llama-swap`, `vimPlugins.llama-vim`, nixvim, nvim-cmp/luasnip.

**Verified facts (from upstream sources, 2026-06-05):**
- llama.vim default `endpoint_fim` = `http://127.0.0.1:8012/infill`; we override to route through llama-swap.
- llama.vim default keymaps: `keymap_fim_accept_full` = `<Tab>`, `keymap_fim_accept_line` = `<S-Tab>`, `keymap_fim_accept_word` = `<leader>ll]`. Accept maps are created **buffer-locally via `inoremap`** in `s:fim_render()`, only while a hint is shown.
- llama.vim public functions: `llama#is_fim_hint_shown()` (returns `v:true`/`v:false`), `llama#fim_accept('full'|'line'|'word')`. Commands: `LlamaEnable`, `LlamaDisable`, `LlamaToggle`, `LlamaStatus`.
- llama-swap config: `models.<id>.cmd` (uses `${PORT}` macro), `models.<id>.ttl` (idle-unload seconds). CLI: `llama-swap --config <yaml> --listen <addr:port>`. Native upstream routing: `/upstream/<model_id>/<path>`. Manual unload: `POST /api/models/unload` (all) or `POST /api/models/unload/<model_id>`.
- Canonical llama.vim 7B server flags: `-ngl 99 -fa -ub 1024 -b 1024 --ctx-size <n> --cache-reuse 256`.

---

## File Structure

| Action | File | Responsibility |
|---|---|---|
| Create | `home/programs/llama-completion.nix` | model derivation + CUDA llama-cpp + llama-swap user service + config YAML + shell aliases |
| Create | `home/programs/nixvim/ai-completion.nix` | `llama.vim` plugin + `g:llama_config` (endpoint, relocated keymaps) |
| Modify | `home/programs/nixvim/default.nix` | import `ai-completion.nix` |
| Modify | `home/programs/nixvim/completion.nix` | add AI-accept branch to the `<Tab>` mapping |
| Modify | `home/sakost.nix` | import `home/programs/llama-completion.nix` |

**Note on "tests":** This is a declarative NixOS config; the verification gate after each change is a successful evaluation/build (`nixos-rebuild build --flake .#sakost-pc`), and the final task is manual acceptance against the running system. There are no unit-test files.

---

## Task 1: Model derivation + server module (build only, no service yet)

Create the server-side module with the GGUF derivation and CUDA llama-cpp, but **without** wiring the systemd service yet, so we can isolate the (potentially long) CUDA build and the model fetch hash before adding runtime config.

**Files:**
- Create: `home/programs/llama-completion.nix`

- [ ] **Step 1: Write the module with a placeholder model hash**

Create `home/programs/llama-completion.nix`:

```nix
# Local, offline AI inline-completion backend for Neovim.
#
# A single Qwen2.5-Coder-7B (base, FIM) model is served by a CUDA llama-server
# that is lazy-loaded by llama-swap on the first request from any nvim instance
# and unloaded after a 10-minute idle TTL. The editor side lives in
# home/programs/nixvim/ai-completion.nix and talks to the proxy below.
{ pkgs, lib, ... }:

let
  # ---- Model (base coder model — required for FIM; instruct degrades) -------
  # Q5_K_M is the VRAM/quality sweet spot on a 16 GB RTX 4080 (~5.4 GB),
  # leaving ~10 GB free for the desktop/games. Bump to Q6_K/Q8_0 by changing
  # the url + hash below.
  model = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/Qwen2.5-Coder-7B-GGUF/resolve/main/Qwen2.5-Coder-7B-Q5_K_M.gguf";
    # Replace with the real hash from `nix store prefetch-file` (see plan Step 3).
    hash = lib.fakeHash;
  };

  # ---- Inference runtime: CUDA llama.cpp for full GPU offload ---------------
  llamaCpp = pkgs.llama-cpp.override { cudaSupport = true; };

  # ---- Server endpoint the proxy exposes -----------------------------------
  proxyPort = 8080;
in
{
  # Expose the pieces other modules / future steps consume. Nothing is wired
  # to a service yet — Task 2 adds the systemd user unit.
  _module.args.llamaCompletion = {
    inherit model llamaCpp proxyPort;
  };
}
```

- [ ] **Step 2: Import it so it evaluates**

In `home/sakost.nix`, add the import inside the `imports = [ ... ]` list, right after `./programs/nixvim`:

```nix
    ./programs/nixvim
    ./programs/llama-completion.nix
```

- [ ] **Step 3: Get the real model hash**

Run:

```bash
nix store prefetch-file --hash-type sha256 \
  "https://huggingface.co/bartowski/Qwen2.5-Coder-7B-GGUF/resolve/main/Qwen2.5-Coder-7B-Q5_K_M.gguf"
```

Expected: prints `Downloaded ... to /nix/store/...` and a line `hash: sha256-....`. Copy the `sha256-...` value.

(If `bartowski/Qwen2.5-Coder-7B-GGUF` lacks that exact filename, list the repo's files at `https://huggingface.co/bartowski/Qwen2.5-Coder-7B-GGUF/tree/main` and pick the `*-Q5_K_M.gguf` filename, updating both the `url` and the prefetch command.)

- [ ] **Step 4: Replace the placeholder hash**

In `home/programs/llama-completion.nix`, replace `hash = lib.fakeHash;` with the prefetched value, e.g.:

```nix
    hash = "sha256-REPLACE_WITH_PREFETCHED_VALUE";
```

- [ ] **Step 5: Build to verify the module evaluates and the model fetches**

Run:

```bash
nixos-rebuild build --flake .#sakost-pc 2>&1 | tail -20
```

Expected: build succeeds. The CUDA llama-cpp may compile from source (can take 20–40 min the first time if not cached) — that is expected, not an error. If it fails on `hash mismatch`, copy the "got:" hash into Step 4 and rebuild.

- [ ] **Step 6: Commit**

```bash
git add home/programs/llama-completion.nix home/sakost.nix
git commit -m "feat(home): add Qwen2.5-Coder-7B model + CUDA llama-cpp for nvim AI completion"
```

---

## Task 2: llama-swap user service (on-demand server + idle unload + aliases)

Wire the always-on proxy that lazy-loads the model and frees VRAM on idle, plus the `llm-stop`/`llm-status` kill switch.

**Files:**
- Modify: `home/programs/llama-completion.nix`

- [ ] **Step 1: Add the llama-swap config, systemd user service, and aliases**

Replace the entire body of `home/programs/llama-completion.nix` with:

```nix
# Local, offline AI inline-completion backend for Neovim.
#
# A single Qwen2.5-Coder-7B (base, FIM) model is served by a CUDA llama-server
# that is lazy-loaded by llama-swap on the first request from any nvim instance
# and unloaded after a 10-minute idle TTL. The editor side lives in
# home/programs/nixvim/ai-completion.nix and talks to the proxy below.
{ pkgs, lib, ... }:

let
  # ---- Model (base coder model — required for FIM; instruct degrades) -------
  # Q5_K_M is the VRAM/quality sweet spot on a 16 GB RTX 4080 (~5.4 GB),
  # leaving ~10 GB free for the desktop/games. Bump to Q6_K/Q8_0 by changing
  # the url + hash below.
  model = pkgs.fetchurl {
    url = "https://huggingface.co/bartowski/Qwen2.5-Coder-7B-GGUF/resolve/main/Qwen2.5-Coder-7B-Q5_K_M.gguf";
    hash = "sha256-REPLACE_WITH_PREFETCHED_VALUE";  # from Task 1 Step 3
  };

  # ---- Inference runtime: CUDA llama.cpp for full GPU offload ---------------
  llamaCpp = pkgs.llama-cpp.override { cudaSupport = true; };

  proxyPort = 8080;
  modelId = "qwen-coder";

  # ---- llama-swap config: one lazy-loaded model with idle unload -----------
  # ${PORT} is substituted by llama-swap. -ngl 99 offloads all layers to the
  # GPU; --ctx-size 8192 bounds the KV-cache VRAM (FIM only needs a few k
  # tokens of context); --cache-reuse 256 speeds up repeated prefixes; ttl
  # unloads the model (frees VRAM) after 600 s idle.
  swapConfig = pkgs.writeText "llama-swap.yaml" ''
    models:
      "${modelId}":
        cmd: >
          ${llamaCpp}/bin/llama-server
          -m ${model}
          --port ''${PORT}
          -ngl 99
          -fa on
          -ub 1024
          -b 1024
          --ctx-size 8192
          --cache-reuse 256
        ttl: 600
  '';
in
{
  # llama-swap as a user service: tiny, always listening, zero VRAM until a
  # request arrives. Shared by every nvim instance.
  systemd.user.services.llama-swap = {
    Unit = {
      Description = "llama-swap — on-demand local LLM proxy for nvim completion";
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.llama-swap}/bin/llama-swap --config ${swapConfig} --listen 127.0.0.1:${toString proxyPort}";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Kill switch + status for when the GPU is needed elsewhere (games).
  home.shellAliases = {
    llm-stop = "curl -s -X POST http://127.0.0.1:${toString proxyPort}/api/models/unload && echo ' -> model unloaded'";
    llm-status = "curl -s http://127.0.0.1:${toString proxyPort}/api/models";
  };

  # Used by home/programs/nixvim/ai-completion.nix to build the endpoint URL.
  _module.args.llamaCompletion = { inherit proxyPort modelId; };
}
```

- [ ] **Step 2: Build to verify evaluation**

Run:

```bash
nixos-rebuild build --flake .#sakost-pc 2>&1 | tail -20
```

Expected: build succeeds. (If you see an error about `--listen` or `-fa on` only at *runtime*, it is handled in Task 5 Step 2; evaluation here only proves the Nix is valid.)

- [ ] **Step 3: Commit**

```bash
git add home/programs/llama-completion.nix
git commit -m "feat(home): add llama-swap user service with idle unload + llm-stop alias"
```

---

## Task 3: Add llama.vim to nixvim with relocated keymaps

Add the ghost-text plugin and point it at the proxy. Relocate its `<Tab>`/`<S-Tab>` accept maps into its own `<leader>ll*` namespace so they never shadow cmp.

**Files:**
- Create: `home/programs/nixvim/ai-completion.nix`
- Modify: `home/programs/nixvim/default.nix`

- [ ] **Step 1: Create the nixvim AI-completion module**

Create `home/programs/nixvim/ai-completion.nix`:

```nix
# AI ghost-text inline completion via llama.vim.
#
# Talks to the local llama-swap proxy (see home/programs/llama-completion.nix),
# which lazy-loads Qwen2.5-Coder-7B. Coexists with nvim-cmp: the <Tab>
# arbitration lives in completion.nix and calls llama#fim_accept('full').
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
```

- [ ] **Step 2: Import it**

In `home/programs/nixvim/default.nix`, add `./ai-completion.nix` to the `imports` list, right after `./completion.nix`:

```nix
    ./completion.nix
    ./ai-completion.nix
```

- [ ] **Step 3: Build to verify evaluation**

Run:

```bash
nixos-rebuild build --flake .#sakost-pc 2>&1 | tail -20
```

Expected: build succeeds. If it errors with `attribute 'llamaCompletion' missing`, confirm Task 2 Step 1 exported `_module.args.llamaCompletion` with `proxyPort` and `modelId`.

- [ ] **Step 4: Commit**

```bash
git add home/programs/nixvim/ai-completion.nix home/programs/nixvim/default.nix
git commit -m "feat(nixvim): add llama.vim ghost-text completion via llama-swap"
```

---

## Task 4: `<Tab>` arbitration in cmp

Make `<Tab>` accept the AI ghost text when it is the only thing showing, while keeping cmp and snippets first.

**Files:**
- Modify: `home/programs/nixvim/completion.nix`

- [ ] **Step 1: Add the AI-accept branch to `<Tab>`**

In `home/programs/nixvim/completion.nix`, replace the existing `"<Tab>"` mapping block (the `cmp.mapping(function(fallback) ... end, { 'i', 's' })` for Tab) with this version, which inserts the llama branch between the cmp and snippet branches:

```nix
          "<Tab>" = ''
            cmp.mapping(function(fallback)
              local luasnip = require('luasnip')
              if cmp.visible() then
                cmp.select_next_item()
              elseif vim.fn.exists('*llama#is_fim_hint_shown') == 1
                  and vim.fn['llama#is_fim_hint_shown']() then
                -- AI ghost text is showing and the cmp menu is not — accept it.
                vim.fn['llama#fim_accept']('full')
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { 'i', 's' })
          '';
```

Leave `<S-Tab>`, `<C-l>`, `<C-h>`, and all other mappings unchanged.

- [ ] **Step 2: Build to verify evaluation**

Run:

```bash
nixos-rebuild build --flake .#sakost-pc 2>&1 | tail -20
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add home/programs/nixvim/completion.nix
git commit -m "feat(nixvim): arbitrate <Tab> between cmp, AI ghost text, and snippets"
```

---

## Task 5: Apply and acceptance-test on the live system

Switch to the new config and verify behavior end-to-end, including runtime flags that only surface when the server actually starts.

**Files:** none (operational).

- [ ] **Step 1: Apply the configuration**

Run:

```bash
sudo nixos-rebuild switch --flake .#sakost-pc 2>&1 | tail -20
```

Expected: switch succeeds. Then start/verify the user service:

```bash
systemctl --user daemon-reload
systemctl --user restart llama-swap
systemctl --user status llama-swap --no-pager | head -15
```

Expected: `active (running)`.

- [ ] **Step 2: Confirm the model loads on demand and the server flags are valid**

Trigger a load by hitting the proxy directly (this also surfaces any bad `llama-server` flag such as `-fa on` vs bare `-fa` for this build):

```bash
curl -s -X POST http://127.0.0.1:8080/upstream/qwen-coder/infill \
  -H 'Content-Type: application/json' \
  -d '{"input_prefix":"def add(a, b):\n    return ","input_suffix":"\n","n_predict":16}' | head -c 400
echo
nvidia-smi --query-compute-apps=process_name,used_memory --format=csv,noheader | grep -i llama
```

Expected: JSON with a `content` field containing a completion; `nvidia-smi` shows a `llama-server` process holding ~5–6 GB.
- If the curl fails and `journalctl --user -u llama-swap -n 40 --no-pager` shows `llama-server` rejecting `--flash-attn`/`-fa`, change `-fa on` to bare `-fa` (older builds) — or vice-versa — in `home/programs/llama-completion.nix`, `nixos-rebuild switch`, restart the service, and re-run this step. Commit the fix:
  ```bash
  git add home/programs/llama-completion.nix
  git commit -m "fix(home): correct llama-server flash-attn flag for current build"
  ```

- [ ] **Step 3: Verify ghost text in Neovim**

Open a source file: `nvim /tmp/aitest.py`, enter insert mode, type:

```python
def fibonacci(n):
```

Expected: within ~2 s (first time, while the model warms) gray ghost text proposes a body. Press `<Tab>` → the suggestion is inserted. Press `<leader>lla` mid-suggestion also accepts (alternate binding). Run `:LlamaStatus` → shows the plugin enabled and endpoint reachable.

- [ ] **Step 4: Verify cmp still wins `<Tab>`**

In the same buffer, trigger the cmp popup (type a known symbol / press `<C-Space>`). With the popup visible, press `<Tab>`.

Expected: `<Tab>` cycles the cmp menu (does **not** accept ghost text) — confirming cmp precedence. LSP/snippet/buffer/path completion all still work.

- [ ] **Step 5: Verify sharing across instances (single model)**

Open a **second** terminal, run `nvim /tmp/aitest2.py`, type code to trigger completion. While it works, check VRAM:

```bash
nvidia-smi --query-compute-apps=process_name,used_memory --format=csv,noheader | grep -i llama
```

Expected: completions appear immediately in the second instance and `nvidia-smi` shows **one** `llama-server` process (no extra VRAM) — both editors share it.

- [ ] **Step 6: Verify on-demand VRAM release**

Run the explicit kill switch and confirm VRAM frees:

```bash
llm-stop
sleep 3
nvidia-smi --query-compute-apps=process_name,used_memory --format=csv,noheader | grep -i llama || echo "VRAM freed"
```

Expected: prints `VRAM freed` (no llama process). `llm-status` shows no loaded model. (The 600 s idle `ttl` does this automatically too — optional to wait and confirm.)

- [ ] **Step 7: Final commit (if any runtime fixes were made beyond Step 2)**

```bash
git add -A && git commit -m "chore(home): finalize nvim local AI completion setup" || echo "nothing to commit"
```

---

## Self-Review notes (addressed)

- **Spec coverage:** offline/local (Tasks 1–2), shared across instances (Task 5 Step 5), on-demand + idle TTL + kill switch (Task 2 + Task 5 Step 6), declarative (all Nix), coexists with cmp (Task 4 + Task 5 Step 4), JetBrains Tab-accept (Task 4). All spec requirements map to a task.
- **Known runtime unknowns** are handled with explicit verify-and-fix steps rather than guesses: model filename/hash (Task 1 Step 3), `-fa on` vs `-fa` (Task 5 Step 2), `g:llama_config` partial-merge (proven by Task 5 Step 3 working).
- **Type/name consistency:** `proxyPort`, `modelId`, `llamaCompletion` module arg, and the endpoint path `/upstream/<modelId>/infill` are consistent across Tasks 2–3.
