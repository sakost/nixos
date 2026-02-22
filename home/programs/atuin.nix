# Atuin shell history configuration
{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      filter_mode = "session";
      search_mode = "fuzzy";
      style = "compact";
      inline_height = 20;

      # Local only — no sync
      sync.records = false;
    };
  };
}
