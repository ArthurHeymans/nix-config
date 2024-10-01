{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    vlc
    spotify
    mpv
    evince
    mullvad-vpn
  ];
}
