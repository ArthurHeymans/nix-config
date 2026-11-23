{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.my.features.crypto.enable {
  home.packages = with pkgs; [
    trezor-suite
  ];
}
