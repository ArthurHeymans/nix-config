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
    entire
    pi
    jj-hunk
    jq # often used for parsing nixos output in AI agents
  ];
}
