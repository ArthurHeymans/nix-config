{ pkgs, rust-overlay, ... }:
let
  pkgsWithRust = pkgs.extend rust-overlay.overlays.default;

  rustToolchain = pkgsWithRust.rust-bin.stable."1.90.0".default;

  codex-acp = pkgs.rustPlatform.buildRustPackage rec {
    pname = "codex-acp";
    version = "0.1.5";
    buildInputs = with pkgs;[
      openssl
    ];

    src = pkgs.fetchFromGitHub {
      owner = "cola-io";
      repo = "codex-acp";
      rev = "v0.1.5";
      hash = "sha256-SEZNUJjjkRDnWPXgrswXWcgm812bVOAFARlMnzGTtf8=";
    };

    cargoHash = "sha256-uK3Y5tEhcAjahtjJXpwE6PT+SCU08TfhXvRbe7n9aB8=";

    # Use custom Rust toolchain
    nativeBuildInputs = [ rustToolchain pkgs.pkg-config];
  };
in
{
  home.packages =
    with pkgs;
    [
      #aider-chat
      codex
      gemini-cli
      opencode
      jq # often used for parsing nixos output in AI agents
    ]
    ++ [ codex-acp ];
}
