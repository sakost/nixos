# Git configuration
{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.git-ai.homeManagerModules.default ];

  # git-ai wraps git and tracks AI-generated code attribution in git notes
  programs.git-ai = {
    enable = true;
    installHooks = true;
  };

  programs.git = {
    enable = true;
    package = inputs.git-ai.packages.${pkgs.system}.default;

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
      credential.helper = "libsecret";
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
