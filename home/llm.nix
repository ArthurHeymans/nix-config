{ config, pkgs, pkgs-unstable, ... }:

{
  home.packages = with pkgs-unstable; [
    ollama
    mods
  ];
}
