# Ollama — local LLM inference service
{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };
}
