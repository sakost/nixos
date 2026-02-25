# Starship prompt configuration
{ theme, ... }:

let
  c = theme.colors;
in
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = "$directory$git_branch$git_status$nix_shell$rust$golang$python$nodejs$kubernetes$line_break$character";

      character = {
        success_symbol = "[❯](bold ${c.accent})";
        error_symbol = "[❯](bold ${c.error})";
      };

      directory = {
        style = "bold ${c.accent}";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bold ${c.magenta}";
        symbol = builtins.fromJSON ''"\ue0a0"'' + " ";
      };

      git_status = {
        style = "bold ${c.yellow}";
      };

      nix_shell = {
        style = "bold ${c.cyan}";
        symbol = builtins.fromJSON ''"\uf313"'' + " ";
        format = "via [$symbol$name]($style) ";
      };

      rust = {
        style = "bold ${c.red}";
        symbol = builtins.fromJSON ''"\ue7a8"'' + " ";
      };

      golang = {
        style = "bold ${c.teal}";
        symbol = builtins.fromJSON ''"\ue627"'' + " ";
      };

      python = {
        style = "bold ${c.yellow}";
        symbol = builtins.fromJSON ''"\ue73c"'' + " ";
        detect_files = [ "pyproject.toml" "setup.py" "setup.cfg" "requirements.txt" "Pipfile" "tox.ini" ];
        detect_folders = [ ".venv" "venv" ];
        detect_extensions = [];
      };

      nodejs = {
        style = "bold ${c.green}";
        symbol = builtins.fromJSON ''"\ue718"'' + " ";
      };

      kubernetes = {
        disabled = true;
        style = "bold ${c.cyan}";
        symbol = "☸ ";
      };
    };
  };
}
