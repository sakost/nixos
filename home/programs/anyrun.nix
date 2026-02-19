# Anyrun — Wayland-native application launcher
{ pkgs, ... }:

{
  home.packages = [ pkgs.anyrun ];

  # Main config
  xdg.configFile."anyrun/config.ron".text = ''
    Config(
      // Position
      x: Fraction(0.5),
      y: Fraction(0.3),
      width: Fraction(0.35),

      // Behavior
      hide_icons: false,
      hide_plugin_info: false,
      close_on_click: false,
      show_results_immediately: true,
      max_entries: Some(10),
      layer: Overlay,
      ignore_exclusive_zones: false,

      // Plugins (bundled with anyrun)
      plugins: [
        "${pkgs.anyrun}/lib/libapplications.so",
        "${pkgs.anyrun}/lib/libsymbols.so",
        "${pkgs.anyrun}/lib/librink.so",
        "${pkgs.anyrun}/lib/libshell.so",
      ],
    )
  '';

  # TokyoNight-inspired dark theme
  xdg.configFile."anyrun/style.css".text = ''
    * {
      all: unset;
      font-family: "JetBrainsMono Nerd Font", monospace;
      font-size: 14px;
    }

    #window {
      background: transparent;
    }

    box#main {
      background: rgba(26, 27, 38, 0.92);
      border: 2px solid rgba(122, 162, 247, 0.6);
      border-radius: 16px;
      padding: 8px;
    }

    entry#entry {
      background: rgba(36, 40, 59, 0.9);
      border: 1px solid rgba(122, 162, 247, 0.4);
      border-radius: 12px;
      padding: 10px 16px;
      margin: 4px 8px;
      color: #c0caf5;
      caret-color: #7aa2f7;
      font-size: 16px;
    }

    entry#entry:focus {
      border-color: rgba(122, 162, 247, 0.8);
    }

    entry#entry placeholder {
      color: rgba(169, 177, 214, 0.5);
    }

    list#main {
      background: transparent;
      margin: 4px 0;
    }

    row#entry {
      padding: 6px 12px;
      margin: 2px 4px;
      border-radius: 10px;
      color: #a9b1d6;
    }

    row#entry:selected {
      background: rgba(122, 162, 247, 0.2);
      color: #c0caf5;
    }

    row#entry:hover {
      background: rgba(122, 162, 247, 0.1);
    }

    box#plugin {
      padding: 4px 0;
    }

    label#info {
      color: rgba(169, 177, 214, 0.6);
      font-size: 12px;
    }

    label#match-desc {
      color: rgba(169, 177, 214, 0.7);
      font-size: 12px;
    }
  '';

  # Symbols plugin config
  xdg.configFile."anyrun/symbols.ron".text = ''
    Config(
      prefix: ":s",
      max_entries: 5,
    )
  '';

  # Shell plugin config
  xdg.configFile."anyrun/shell.ron".text = ''
    Config(
      prefix: ":sh",
      shell: Some("zsh"),
    )
  '';
}
