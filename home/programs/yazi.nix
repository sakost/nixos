# Yazi file manager configuration
{ pkgs, ... }:

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

      opener = {
        edit = [{ run = ''nvim "$@"''; block = true; }];
        pdf = [{ run = ''zathura "$@"''; orphan = true; }];
        image = [{ run = ''xdg-open "$@"''; orphan = true; }];
        video = [{ run = ''xdg-open "$@"''; orphan = true; }];
        fallback = [{ run = ''xdg-open "$@"''; orphan = true; }];
      };

      open.rules = [
        { mime = "text/*"; use = "edit"; }
        { mime = "application/json"; use = "edit"; }
        { mime = "*/xml"; use = "edit"; }
        { name = "*.nix"; use = "edit"; }
        { mime = "application/pdf"; use = "pdf"; }
        { mime = "image/*"; use = "image"; }
        { mime = "video/*"; use = "video"; }
        { name = "*"; use = "fallback"; }
      ];
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
