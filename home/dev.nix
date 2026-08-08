{
  lib,
  pkgs,
  ...
}:
let
  ghidra-cli = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ghidra-cli";
    version = "0.2.2";

    src = pkgs.fetchFromGitHub {
      owner = "akiselev";
      repo = "ghidra-cli";
      rev = "v${version}";
      hash = "sha256-B4bnOOFtEsckT5TOAmjbx5AkrdpjeA248G+BrDUHY88=";
    };

    cargoHash = "sha256-r8AvlTJQ+j5YoLGJe3xIA0q+DPDTMKfhlT+nwFfNsPw=";

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
    qemu

    # reverse engineering
    ghidra
    (lib.hiPrio ghidra-cli) # binary is also named `ghidra`, takes precedence over GUI
  ];
}
