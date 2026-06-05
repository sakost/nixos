# Local, offline AI inline-completion backend for Neovim.
#
# A single Qwen2.5-Coder-7B (base, FIM) model is served by a CUDA llama-server
# that is lazy-loaded by llama-swap on the first request from any nvim instance
# and unloaded after a 10-minute idle TTL. The editor side lives in
# home/programs/nixvim/ai-completion.nix and talks to the proxy below.
{ pkgs, ... }:

let
  # ---- Model (base coder model — required for FIM; instruct degrades) -------
  # Q5_K_M is the VRAM/quality sweet spot on a 16 GB RTX 4080 (~5.4 GB),
  # leaving ~10 GB free for the desktop/games. Bump to Q6_K/Q8_0 by changing
  # the url + hash below.
  model = pkgs.fetchurl {
    url = "https://huggingface.co/QuantFactory/Qwen2.5-Coder-7B-GGUF/resolve/main/Qwen2.5-Coder-7B.Q5_K_M.gguf";
    hash = "sha256-rG/F5MB8fMctAPxNzlMW348dK7xdyoPAX0OmcLQ7lME=";
  };

  # ---- Inference runtime: CUDA llama.cpp for full GPU offload ---------------
  llamaCpp = pkgs.llama-cpp.override { cudaSupport = true; };

  proxyPort = 11435;
  modelId = "qwen-coder";

  # ---- llama-swap config: one lazy-loaded model with idle unload -----------
  # ''${PORT} is substituted by llama-swap. -ngl 99 offloads all layers to the
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
