{ pkgs, ... }:

{
  home.packages = with pkgs; [
    trezor-suite
  ];
}
