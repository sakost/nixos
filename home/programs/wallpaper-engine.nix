# Wallpaper Engine via linux-wallpaperengine
{ ... }:

{
  services.linux-wallpaperengine = {
    enable = true;
    assetsPath = "/home/sakost/games/SteamLibrary/steamapps/common/wallpaper_engine/assets";
    wallpapers = [
      {
        monitor = "DP-2";
        wallpaperId = "/home/sakost/games/SteamLibrary/steamapps/workshop/content/431960/3470915045";
        fps = 60;
      }
    ];
  };
}
