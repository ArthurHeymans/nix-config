{
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    rustup
    cargo-binutils
    cargo-nextest
    cargo-bloat
    flip-link
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
    probe-rs-tools
    espflash
    wlink
    gdb
    lldb
    jujutsu
    llvmPackages.bintools
  ];
}
