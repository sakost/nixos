# Yazi file manager configuration
{ theme, ... }:

let
  c = theme.colors;
in
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
        cwd = { fg = c.accent; };
        hovered = { bg = c.selection; };
        preview_hovered = { bg = c.selection; };
      };

      status = {
        separator_open = "";
        separator_close = "";
      };

      filetype = {
        rules = [
          { mime = "image/*"; fg = c.magenta; }
          { mime = "video/*"; fg = c.yellow; }
          { mime = "audio/*"; fg = c.yellow; }
          { name = "*.nix"; fg = c.cyan; }
        ];
      };
    };
  };
}
