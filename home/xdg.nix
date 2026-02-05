# XDG Base Directory configuration
{ config, ... }:

{
  # Environment variables for XDG compliance
  home.sessionVariables = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    GOPATH = "${config.xdg.dataHome}/go";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonstartup.py";
    CUDA_CACHE_PATH = "${config.xdg.cacheHome}/nv";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
  };

  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      download = "${config.home.homeDirectory}/Downloads";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";
      templates = "${config.home.homeDirectory}/Templates";
      publicShare = "${config.home.homeDirectory}/Public";
    };

    # NPM configuration for XDG compliance
    configFile."npm/npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${config.xdg.cacheHome}/npm
    '';
  };
}
