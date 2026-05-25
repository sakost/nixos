# Hyprland plugin overrides for compatibility with Hyprland 0.55.
# TODO: remove once nixpkgs ships hyprsplit >= 0.55.
final: prev: {
  hyprlandPlugins = prev.hyprlandPlugins // {
    # nixpkgs ships hyprsplit 0.54.2, which fails to compile against Hyprland
    # 0.55 (missing g_pConfigManager / incomplete SWorkspaceRule). Upstream main
    # requires Hyprland >= 0.55.0 and adds the needed includes.
    hyprsplit = prev.hyprlandPlugins.hyprsplit.overrideAttrs (old: {
      version = "0.55-unstable-2026-05-22";
      src = prev.fetchFromGitHub {
        owner = "shezdy";
        repo = "hyprsplit";
        rev = "0fc01e7930625ecb3e069f5dc8e1d61eab929f3b";
        sha256 = "026w0bfkfqaxlrja781987yzzkwyjr2pk6c9rkdh6zr73hb2x72y";
      };
    });
  };
}
