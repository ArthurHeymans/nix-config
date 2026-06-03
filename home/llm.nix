{
  pkgs,
  config,
  llm-agents,
  ...
}: let
  opencode = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode;
  pi = llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
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
in {
  home.packages = with pkgs; [
    opencode
    pi
    jj-hunk
    jq # often used for parsing nixos output in AI agents
  ];

  systemd.user.services.opencode-server = {
    Unit = {
      Description = "OpenCode headless HTTP server";
      After = ["default.target"];
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
      WantedBy = ["default.target"];
    };
  };
}
