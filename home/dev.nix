{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    rustup
    (lib.hiPrio clang)
    # gcc
    gnat13
    gnumake
    python3
    #ncurses
    go
    gopls
    cliphist
    wl-clipboard
    probe-rs
    espflash
  ];
}
