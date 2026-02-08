# XDG Base Directory configuration
{ config, ... }:

let
  cacheBase = "${config.home.homeDirectory}/dev/cache";
in
{
  # Environment variables for XDG compliance
  home.sessionVariables = {
    RUSTUP_HOME = "${config.xdg.dataHome}/rustup";
    GOPATH = "${config.xdg.dataHome}/go";
    GOMODCACHE = "${cacheBase}/go/mod";
    GOCACHE = "${cacheBase}/go/build";
    NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonstartup.py";
    CUDA_CACHE_PATH = "${cacheBase}/cuda";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";

    # Package manager cache directories
    npm_config_cache = "${cacheBase}/npm";
    YARN_CACHE_FOLDER = "${cacheBase}/yarn";
    UV_CACHE_DIR = "${cacheBase}/uv";
    PIP_CACHE_DIR = "${cacheBase}/pip";
    CARGO_HOME = "${cacheBase}/cargo";
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

    # Python startup file for XDG compliance
    configFile."python/pythonstartup.py".text = "";

    # NPM configuration for XDG compliance
    configFile."npm/npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${cacheBase}/npm
    '';
  };
}
