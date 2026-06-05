# Local AI inline completion for Neovim — Design

**Date:** 2026-06-05
**Status:** Approved (design), pending implementation plan
**Scope:** Add JetBrains-style, fully-offline, AI-powered inline (ghost-text) completion to the nixvim setup, shared across all Neovim instances, running locally on the RTX 4080.

## Goal

Replicate JetBrains' "Full Line Completion" experience in Neovim: a small code model that, as you type, predicts whole lines/blocks shown as gray ghost text ahead of the cursor, accepted with `<Tab>`. It must be:

- **Offline** — no internet, no account, no subscription. Local model on the GPU.
- **Shared** — a single model instance serves every running Neovim instance.
- **On-demand** — VRAM is consumed only while actively coding; freed after an idle timeout, plus an explicit kill switch (the user games on the same GPU).
- **Declarative** — everything lives in the flake; reproducible, no manual steps.
- **Complementary** — coexists with the existing `nvim-cmp` symbolic popup, does not replace it.

## Hardware / context

- GPU: **NVIDIA RTX 4080, 16 GB VRAM** (also used for desktop + games).
- Existing completion: `nvim-cmp` with LSP / luasnip / buffer / path sources (`home/programs/nixvim/completion.nix`).
- nixvim is integrated as a home-manager module; per-program configs live in `home/programs/nixvim/`.

## Chosen stack (and why)

| Concern | Choice | Rationale |
|---|---|---|
| Inference runtime | **llama.cpp** (`llama-server`, CUDA build, `/infill` FIM endpoint) | Leanest runtime → best tokens/sec per GB VRAM. Native FIM. |
| Model | **`qwen2.5-coder-7b-instruct` GGUF @ Q5_K_M (~5.4 GB)** | Best open coder model with native FIM. Q5 ≈ near-Q8 quality, fast on a 4080, leaves ~10 GB VRAM free. |
| On-demand lifecycle + sharing | **`llama-swap`** proxy | Always-listening tiny proxy (≈0 VRAM idle). Lazy-loads `llama-server` on first request, unloads after idle `ttl`. Single stable endpoint that all nvim clients share. Adds the idle-unload capability `llama-server` lacks natively. |
| Editor integration | **`llama.vim`** | Purpose-built ghost-text FIM plugin by the llama.cpp author. Smart cross-file "ring buffer" context for free. |

**Rejected alternatives:** Tabby (extra embedding model + indexing daemon → worse VRAM ROI for marginal context gains); minuet-ai (more tuning, blends into cmp popup rather than the JetBrains ghost-text feel); cloud backends Copilot/Codeium/Supermaven (require internet/account — fails the offline requirement); bare socket-activated `llama-server` (no native idle-unload).

## Architecture / data flow

```
┌─ nvim #1 ─┐
├─ nvim #2 ─┤── llama.vim ──HTTP /infill──▶  llama-swap (127.0.0.1:8080)  ──▶  llama-server
└─ nvim #3 ─┘   (ghost text)                 always-on, ~0 VRAM idle           qwen2.5-coder-7b
                                             lazy-load on request               -ngl 99 (full GPU offload)
                                             unload after ttl (idle)            /infill FIM endpoint
```

- All Neovim instances point `llama.vim` at the **same** llama-swap endpoint → one shared model.
- First `/infill` request from any client triggers llama-swap to start `llama-server` (warm-up ~1–2 s).
- After `ttl` seconds idle, llama-swap stops `llama-server`, freeing VRAM.

## Components

### 1. Model (declarative + offline)
- `qwen2.5-coder-7b-instruct-q5_k_m.gguf` fetched via a pinned `fetchurl`/`fetchHuggingFace`-style derivation (sha256-locked) so it resides in the Nix store. No runtime download.
- Q5_K_M default; changing quant = changing the URL + hash in one place. Documented in-file.

### 2. `llama-swap` systemd **user** service (home-manager)
- `systemd.user.services.llama-swap` runs `llama-swap --config <generated.yaml> --listen 127.0.0.1:8080`.
- Generated YAML config defines one model `qwen-coder`:
  - command: `llama-server -m <store-path-to-gguf> -ngl 99 --port ${PORT} -fa` plus FIM-appropriate context/cache flags (exact flags verified against llama.vim's recommended server invocation during implementation).
  - `ttl: 600` (10-minute idle unload).
- Uses the **CUDA** variant of `llama-cpp` (`llama-cpp.override { cudaSupport = true; }` or the cuda package), ensuring GPU offload.
- Negligible idle cost; VRAM only while a model is loaded.

### 3. Explicit kill switch (zsh)
- `llm-stop` — `curl` llama-swap's unload endpoint (or `systemctl --user stop llama-swap`) to free VRAM immediately.
- `llm-status` — query llama-swap for currently-loaded model / running state.
- (Plugin-side) `:LlamaDisable` / `:LlamaEnable` from llama.vim to silence requests per-editor.

### 4. `llama.vim` in nixvim
- Added via nixvim `extraPlugins` (`pkgs.vimPlugins.llama-vim`) with `g:llama_config` set: endpoint = `http://127.0.0.1:8080/...` (exact path for routing through llama-swap to the `/infill` endpoint verified during implementation), ghost-text appearance, and keymap overrides so its accept key does not blindly grab `<Tab>` (arbitration handled in completion.nix instead).
- Coexists with `nvim-cmp`.

## Neovim integration — `<Tab>` arbitration

`<Tab>` becomes a 4-way decision (extends the existing mapping in `completion.nix`):

```
<Tab> →  cmp popup visible?         → cmp.select_next_item()
         else llama ghost text up?  → accept the AI suggestion
         else luasnip jumpable?     → luasnip.expand_or_jump()
         else                       → fallback() (literal tab)
```

Ordering rationale: the explicit, LSP-accurate cmp menu wins over speculative AI ghost text; the AI suggestion only claims `<Tab>` once the popup is dismissed/absent — mirroring how JetBrains layers Full Line Completion *under* its symbol popup. `<S-Tab>` keeps its existing prev-item / snippet-jump-back behavior (no AI branch needed).

## Files

| Action | File | Purpose |
|---|---|---|
| **New** | `home/programs/llama-completion.nix` | model derivation + `llama-swap` user service + CUDA `llama-cpp` + zsh `llm-stop`/`llm-status` aliases |
| **New** | `home/programs/nixvim/ai-completion.nix` | `llama.vim` plugin + `g:llama_config` (endpoint, ghost-text styling, keymap suppression) |
| **Edit** | `home/programs/nixvim/default.nix` | import `ai-completion.nix` |
| **Edit** | `home/programs/nixvim/completion.nix` | add the AI-accept branch to `<Tab>` |
| **Edit** | `home/sakost.nix` | import `home/programs/llama-completion.nix` |

## Error handling / edge cases

- **Server not yet warm:** llama.vim must tolerate the first-request cold start (1–2 s) without throwing; suggestions simply appear once warm. Verify llama.vim's timeout/retry behavior with llama-swap.
- **VRAM pressure while gaming:** `llm-stop` frees VRAM on demand; idle `ttl` is the automatic backstop.
- **Routing native `/infill` through llama-swap:** llama-swap routes OpenAI endpoints by the `model` field; the native `/infill` path needs explicit routing (e.g. `/upstream/<model>/infill`). The exact endpoint string is the main implementation unknown — verify against current llama-swap + llama.vim docs before wiring.
- **No conflict with claudecode.nvim:** that plugin is agentic chat over a side terminal; it shares no keymaps with `<Tab>`/ghost text.

## Testing / acceptance

1. `nixos-rebuild` (via `/check` then `/rebuild`) builds with the new modules.
2. After login, `llm-status` shows the service running with **no** model loaded (0 VRAM).
3. Open a code file in nvim, start typing → gray ghost text appears within ~2 s (first time), `<Tab>` accepts it.
4. `nvidia-smi` shows `llama-server` holding ~5–6 GB while active.
5. Open a **second** nvim instance → completions work immediately with **no** additional VRAM (shared model).
6. Idle 10 min → `nvidia-smi` shows VRAM freed; `llm-stop` frees it immediately on demand.
7. Existing cmp popup (LSP/snippets/buffer/path) still works and still wins `<Tab>` when visible.

## Open implementation details (resolve during planning, verify against current docs)

- Exact `llama-swap` YAML schema for the model entry + `ttl` + listen flags (current v216 syntax).
- Exact `llama.vim` endpoint string to reach `/infill` through llama-swap, and the `g:llama_config` keys for endpoint + appearance + keymap suppression.
- Recommended `llama-server` FIM flags for qwen2.5-coder-7b (context size, `-fa`, cache type) per llama.vim's reference invocation.
- Whether to use `llama-cpp` cuda override vs a dedicated cuda attribute in the flake's nixpkgs.
