{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  piNode = inputs.llm-agents.packages.${system}.pi.override { useBun = false; };
  t3code = import ../packages/t3code.nix { inherit pkgs inputs lib; };
  t3codeServer = pkgs.writeShellScript "t3code-server" ''
    while ${lib.getExe pkgs.netcat-openbsd} -z 127.0.0.1 13773 >/dev/null 2>&1; do
      ${pkgs.coreutils}/bin/sleep 5
    done
    exec ${lib.getExe' t3code "t3"} serve --host 0.0.0.0 --port 13773
  '';
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
    piNode
    jj-hunk
    jq # often used for parsing nixos output in AI agents
    t3code
  ];

  xdg.desktopEntries.t3code-native = {
    name = "T3 Code Desktop";
    comment = "Open the native T3 Code desktop client with T3 Connect support";
    exec = "t3code-desktop";
    icon = "t3code";
    categories = [ "Development" ];
  };

  systemd.user.services.t3code = {
    Unit = {
      Description = "T3 Code server";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = t3codeServer;
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
