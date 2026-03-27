# XDG Base Directory configuration
{ config, pkgs, ... }:

let
  cacheBase = "${config.home.homeDirectory}/dev/cache";
in
{
  # Extra PATH entries
  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
  ];

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
    SUDO_ASKPASS = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";
  };

  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      setSessionVariables = false;
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

    # Podman rootless storage in cache drive
    configFile."containers/storage.conf".text = ''
      [storage]
      driver = "overlay"
      graphroot = "${cacheBase}/podman/storage"
      runroot = "/run/user/1000/containers"
    '';

    # NPM configuration for XDG compliance
    configFile."npm/npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${cacheBase}/npm
    '';

    mimeApps = {
      enable = true;
      defaultApplications = {
        # Web browser — Google Chrome
        "text/html" = "google-chrome.desktop";
        "x-scheme-handler/http" = "google-chrome.desktop";
        "x-scheme-handler/https" = "google-chrome.desktop";
        "x-scheme-handler/about" = "google-chrome.desktop";
        "x-scheme-handler/unknown" = "google-chrome.desktop";

        # File manager — Nautilus
        "inode/directory" = "org.gnome.Nautilus.desktop";

        # Video — mpv
        "video/mp4" = "mpv.desktop";
        "video/x-matroska" = "mpv.desktop";
        "video/webm" = "mpv.desktop";
        "video/x-msvideo" = "mpv.desktop";
        "video/quicktime" = "mpv.desktop";
        "video/x-flv" = "mpv.desktop";
        "video/ogg" = "mpv.desktop";
        "video/mpeg" = "mpv.desktop";
        "video/3gpp" = "mpv.desktop";
        "video/x-ogm+ogg" = "mpv.desktop";

        # Images — Eye of GNOME (loupe)
        "image/png" = "org.gnome.Loupe.desktop";
        "image/jpeg" = "org.gnome.Loupe.desktop";
        "image/gif" = "org.gnome.Loupe.desktop";
        "image/webp" = "org.gnome.Loupe.desktop";
        "image/svg+xml" = "org.gnome.Loupe.desktop";
        "image/bmp" = "org.gnome.Loupe.desktop";
        "image/tiff" = "org.gnome.Loupe.desktop";

        # PDF / documents — Zathura
        "application/pdf" = "org.pwmt.zathura.desktop";

        # Text — Neovim (via terminal)
        "text/plain" = "nvim.desktop";
        "text/x-csrc" = "nvim.desktop";
        "text/x-python" = "nvim.desktop";
        "text/x-shellscript" = "nvim.desktop";
        "application/json" = "nvim.desktop";
        "application/xml" = "nvim.desktop";
        "application/x-yaml" = "nvim.desktop";

        # Telegram links
        "x-scheme-handler/tg" = "org.telegram.desktop.desktop";

        # Audio — mpv
        "audio/mpeg" = "mpv.desktop";
        "audio/flac" = "mpv.desktop";
        "audio/ogg" = "mpv.desktop";
        "audio/wav" = "mpv.desktop";
        "audio/x-wav" = "mpv.desktop";
        "audio/mp4" = "mpv.desktop";
        "audio/aac" = "mpv.desktop";
      };
    };

  };
}
