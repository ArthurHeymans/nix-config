{
  lib,
  pkgs,
  ...
}:
let
  ghidra-cli = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ghidra-cli";
    version = "0.1.9";

    src = pkgs.fetchFromGitHub {
      owner = "akiselev";
      repo = "ghidra-cli";
      rev = "v${version}";
      hash = "sha256-bX+lT4YeBJkOLPW+db/4CCimnLUjdc6/REk5+5PtBEE=";
    };

    cargoHash = "sha256-J+XhpIo5T/6kotHH51XEyxYLVsjJ/+p0EXTKqhef/oc=";

    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl ];

    # tests require a ghidra installation at build time
    doCheck = false;
  };
in
{
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
    probe-rs-tools
    sunxi-tools
    espflash
    wlink
    gdb
    lldb
    jujutsu
    llvmPackages.bintools

    # reverse engineering
    ghidra
    (lib.hiPrio ghidra-cli) # binary is also named `ghidra`, takes precedence over GUI
  ];
}
