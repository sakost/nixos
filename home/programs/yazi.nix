# Yazi file manager configuration
{ ... }:

{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";

    settings = {
      manager = {
        show_hidden = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };

    theme = {
      manager = {
        cwd = { fg = "#7aa2f7"; };
        hovered = { bg = "#283457"; };
        preview_hovered = { bg = "#283457"; };
      };

      status = {
        separator_open = "";
        separator_close = "";
      };

      filetype = {
        rules = [
          { mime = "image/*"; fg = "#bb9af7"; }
          { mime = "video/*"; fg = "#e0af68"; }
          { mime = "audio/*"; fg = "#e0af68"; }
          { name = "*.nix"; fg = "#7dcfff"; }
        ];
      };
    };
  };
}
