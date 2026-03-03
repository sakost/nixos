# Override Hyprland plugins to commits compatible with Hyprland 0.54
# TODO: remove once nixpkgs updates hyprland-plugins and hyprsplit
final: prev:
let
  # hyprwm/hyprland-plugins: "all: chase hyprland" — fixes LayoutManager.hpp removal
  hyprland-plugins-src = prev.fetchFromGitHub {
    owner = "hyprwm";
    repo = "hyprland-plugins";
    rev = "b85a56b9531013c79f2f3846fd6ee2ff014b8960";
    hash = "sha256-xwNa+1D8WPsDnJtUofDrtyDCZKZotbUymzV/R5s+M0I=";
  };
in {
  hyprlandPlugins = prev.hyprlandPlugins // {
    # hyprwinwrap 0.53.0 → HEAD: fixes LayoutManager.hpp missing in 0.54
    hyprwinwrap = prev.hyprlandPlugins.hyprwinwrap.overrideAttrs (_: {
      src = "${hyprland-plugins-src}/hyprwinwrap";
    });

    # hyprsplit 0.53.1 → HEAD: fixes HookSystemManager.hpp missing in 0.54
    hyprsplit = prev.hyprlandPlugins.hyprsplit.overrideAttrs (_: {
      src = prev.fetchFromGitHub {
        owner = "shezdy";
        repo = "hyprsplit";
        rev = "1d8ab25e03a68e136a5534c25890da2e5b25488b";
        hash = "sha256-0/b9n3NvXiA2NGz2Bt/h8TLyBc+twJiHriHyI8JovdI=";
      };
    });
  };
}
