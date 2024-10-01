{
  config,
  lib,
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    rustup
    #clang
    # gcc
    #gnat13
    gnumake
    python3
  ];
}
