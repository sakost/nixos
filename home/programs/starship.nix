# Starship prompt configuration
{ ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      format = "$directory$git_branch$git_status$nix_shell$rust$golang$python$nodejs$kubernetes$line_break$character";

      character = {
        success_symbol = "[❯](bold #7aa2f7)";
        error_symbol = "[❯](bold #f7768e)";
      };

      directory = {
        style = "bold #7aa2f7";
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        style = "bold #bb9af7";
        symbol = " ";
      };

      git_status = {
        style = "bold #e0af68";
      };

      nix_shell = {
        style = "bold #7dcfff";
        symbol = " ";
        format = "via [$symbol$state]($style) ";
      };

      rust = {
        style = "bold #f7768e";
        symbol = " ";
      };

      golang = {
        style = "bold #73daca";
        symbol = " ";
      };

      python = {
        style = "bold #e0af68";
        symbol = " ";
        detect_files = [ "pyproject.toml" "setup.py" "setup.cfg" "requirements.txt" "Pipfile" "tox.ini" ];
        detect_folders = [ ".venv" "venv" ];
        detect_extensions = [];
      };

      nodejs = {
        style = "bold #9ece6a";
        symbol = " ";
      };

      kubernetes = {
        disabled = true;
        style = "bold #7dcfff";
        symbol = "☸ ";
      };
    };
  };
}
