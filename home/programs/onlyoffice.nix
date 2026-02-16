# OnlyOffice — Microsoft Office alternative with native OOXML support
{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    onlyoffice-desktopeditors
  ];
}
