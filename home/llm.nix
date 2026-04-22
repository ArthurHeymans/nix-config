{
  pkgs,
  config,
  rust-overlay,
  llm-agents,
  ...
}:
let
  opencode = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  pi = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  pkgsWithRust = pkgs.extend rust-overlay.overlays.default;

  rustToolchain = pkgsWithRust.rust-bin.stable."1.90.0".default;

  codex-acp = pkgs.rustPlatform.buildRustPackage rec {
    pname = "codex-acp";
    version = "0.1.5";
    buildInputs = with pkgs; [
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
    nativeBuildInputs = [
      rustToolchain
      pkgs.pkg-config
    ];
  };
in
{
  home.packages = with pkgs; [
    #aider-chat
    codex
    gemini-cli
    opencode
    pi
    jq # often used for parsing nixos output in AI agents
    # codex-acp
  ];

  systemd.user.services.opencode-server = {
    Unit = {
      Description = "OpenCode headless HTTP server";
      After = [ "default.target" ];
    };
    Service = {
      ExecStart = toString (
        pkgs.writeShellScript "opencode-serve" ''
          export OPENCODE_SERVER_PASSWORD=$(cat ${
            config.sops.secrets."environmentVariables/OPENCODE_SERVER_PASSWORD".path
          })
          exec ${opencode}/bin/opencode serve --hostname 0.0.0.0 --port 4096
        ''
      );
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
