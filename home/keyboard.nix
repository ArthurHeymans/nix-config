{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.my.features.keyboard.enable {
  home.packages = with pkgs; [
    vial
    qmk
  ];
}
