{
  pkgs,
  config,
  llm-agents,
  jcode-src,
  ...
}:
let
  inherit (pkgs) lib stdenv;
  system = pkgs.stdenv.hostPlatform.system;
  pi = llm-agents.packages.${system}.pi;
  jcode = pkgs.rustPlatform.buildRustPackage {
    pname = "jcode";
    version = "0.31.2-${jcode-src.shortRev or "source"}";
    src = jcode-src;

    # Build only the CLI binary.  Upstream also contains probes, benches, and
    # desktop crates that are not needed in the LLM agent package set.
    cargoBuildFlags = [
      "--bin"
      "jcode"
    ];
    cargoTestFlags = [
      "--bin"
      "jcode"
    ];
    doCheck = false;

    cargoLock = {
      lockFile = "${jcode-src}/Cargo.lock";
      outputHashes = {
        "agentgrep-0.1.2" = "sha256-Sf3EmWIZJ29KdaNbYRvM1tFXAPhOGhmpHOyqViEwkRI=";
        "agentgrep-0.1.3" = "sha256-vs8RK85sMa4WVupKU1V2oWxEVs1yHkEy7WNoTCNcMtE=";
        "mermaid-rs-renderer-0.2.0" = "sha256-lQCloOhTqqEU8MNrkUmmJFdoOTEE3j5nvZJo21GJlMU=";
      };
    };

    nativeBuildInputs = with pkgs; [
      cmake
      pkg-config
      perl
    ];

    buildInputs =
      lib.optionals stdenv.isLinux (
        with pkgs;
        [
          fontconfig
          libxkbcommon
          wayland
          libxcb
        ]
      )
      ++ lib.optionals stdenv.isDarwin (
        with pkgs.darwin.apple_sdk.frameworks;
        [
          AppKit
          CoreFoundation
          CoreGraphics
          Foundation
          Security
          SystemConfiguration
        ]
      );

    meta = {
      description = "jcode coding agent harness";
      homepage = "https://github.com/1jehuang/jcode";
      license = lib.licenses.mit;
      mainProgram = "jcode";
    };
  };
  jj-hunk = pkgs.rustPlatform.buildRustPackage rec {
    pname = "jj-hunk";
    version = "0.3.0";

    src = pkgs.fetchCrate {
      inherit pname version;
      hash = "sha256-tuMYEmYhwRLS7pSqS1C+DjNZKZcH4FHsRWmZtUSVBY8=";
    };

    cargoHash = "sha256-S8m3+wFebuezIwqW9Lxtd7PcDUfwJu1VeLMjJopqcSE=";

    # Integration tests shell out to `jj-hunk` itself before the binary is
    # installed in PATH; `cargo install --locked jj-hunk` succeeds locally.
    doCheck = false;
  };
in
{
  home.packages = with pkgs; [
    pi
    jcode
    jj-hunk
    jq # often used for parsing nixos output in AI agents
  ];
}
