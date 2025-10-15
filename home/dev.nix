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
    (pkgs.probe-rs-tools.overrideAttrs (
      finalAttrs: previousAttrs: {
        version = "cda803a77e6da5fa14d312880ad8c347de14464c";

        src = pkgs.fetchFromGitHub {
          owner = "probe-rs";
          repo = "probe-rs";
          rev = "cda803a77e6da5fa14d312880ad8c347de14464c";
          hash = "sha256-eGo41KkTg9ZBces1JcmZBeOA4CwjnvWHPJL23U8Ylk8=";
        };

        # Requires IFD
        cargoDeps = pkgs.rustPlatform.importCargoLock {
          lockFile = finalAttrs.src + "/Cargo.lock";
          allowBuiltinFetchGit = true;
        };
        cargoHash = "";
        cargoBuildFlags = [ "--features=remote" ];
      }
    ))
    espflash
    wlink
    gdb
    lldb
  ];
}
