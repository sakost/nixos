# Temporary overlay: upgrade hyprsplit to v0.53.3 matching Hyprland 0.53.3.
# nixpkgs still packages v0.53.1 which crashes in pluginExit on Hyprland 0.53.3.
# Remove once nixpkgs updates hyprlandPlugins.hyprsplit.
final: prev: {
  hyprlandPlugins = prev.hyprlandPlugins // {
    hyprsplit = prev.hyprlandPlugins.hyprsplit.overrideAttrs (_: {
      version = "0.53.3";
      src = prev.fetchFromGitHub {
        owner = "shezdy";
        repo = "hyprsplit";
        rev = "v0.53.3";
        hash = "sha256-TckWMPtJ5EHPnK11iJagiJoCaSJITAWl2kxk4mop+H8=";
      };
    });
  };
}
