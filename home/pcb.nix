{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.my.features.kicad.enable {
  home.packages = with pkgs; [
    kicad
  ];
}
