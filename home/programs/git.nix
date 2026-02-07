# Git configuration
{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Konstantin Sazhenov";
        email = "me@sakost.dev";
      };
      init.defaultBranch = "master";
      pull.rebase = true;
      push.autoSetupRemote = true;
      merge.conflictstyle = "zdiff3";
      diff.algorithm = "histogram";
      rebase.autoStash = true;
      rerere.enabled = true;
      column.ui = "auto";
      branch.sort = "-committerdate";
      fetch.prune = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      side-by-side = true;
      line-numbers = true;
    };
  };
}
